import { useState } from 'react';
import { useForm, Link, router } from '@inertiajs/react';
import { Inbox, CheckCircle2, Ban } from "lucide-react";
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import PeriodPicker, { isValidStartAt } from "./PeriodPicker";

const TAG_COLORS = ["bg-purple text-white", "bg-orange text-white", "bg-green text-black"];

export default function UserPairRequestCard({ request }) {
  const isCancelled = !!request.cancelled_at;
  const period = request.periods?.[0];
  const isImmediateWaiting = request.mode === "immediate" && !request.accepted_offer && !isCancelled && period;
  const waitUntil = isImmediateWaiting
    ? new Date(period.start_at).getTime() + (request.wait_minutes || 0) * 60000
    : null;
  const isLive = isImmediateWaiting && waitUntil > Date.now();

  const [isRescheduling, setIsRescheduling] = useState(false);

  const { data, setData, patch, processing } = useForm({
    pair_request: {
      sessions_attributes: request.sessions.map(s => ({
        id: s.id,
        call_link: s.call_link || ''
      }))
    }
  });

  const {
    data: rescheduleData,
    setData: setRescheduleData,
    patch: patchReschedule,
    processing: rescheduleProcessing,
    transform: transformReschedule,
  } = useForm({
    pair_request: { periods_attributes: [{ start_at: '' }] }
  });

  const submitCallLink = (e) => {
    e.preventDefault();
    patch(`/users/pair_requests/${request.id}/add_call_link`);
  };

  const submitReschedule = (e) => {
    e.preventDefault();
    transformReschedule((formData) => ({
      pair_request: {
        periods_attributes: formData.pair_request.periods_attributes.map((p) => ({
          ...p,
          start_at: isValidStartAt(p.start_at) ? new Date(p.start_at).toISOString() : '',
        })),
      },
    }));
    patchReschedule(`/users/pair_requests/${request.id}/reschedule`, {
      onSuccess: () => setIsRescheduling(false),
    });
  };

  const cancelRequest = () => {
    if (window.confirm("Cancel this request? You'll still be able to see it in your history.")) {
      router.delete(`/users/pair_requests/${request.id}`);
    }
  };

  return (
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <h3 className="text-xl">{request.subject}</h3>
        <div className="flex gap-2">
          <Button asChild variant="neutral" size="sm">
            <Link href={`/pair_requests/${request.id}/offers`}>
              <Inbox className="h-4 w-4" />
              See applications
            </Link>
          </Button>
          {!isCancelled && !request.accepted_offer && (
            <Button variant="neutral" size="sm" onClick={cancelRequest}>
              Cancel
            </Button>
          )}
        </div>
      </div>

      <ExpandableText className="mt-3 leading-relaxed text-black/60">{request.description}</ExpandableText>

      <div className="mt-4 flex flex-wrap gap-2">
        {request.tags?.map((tag, i) => (
          <Badge key={tag.id} className={`rounded-full border-black ${TAG_COLORS[i % TAG_COLORS.length]}`}>
            {tag.name}
          </Badge>
        ))}
      </div>

      {isCancelled && (
        <div className="mt-4">
          <Badge className="rounded-full border-black bg-black/10 text-black uppercase tracking-widest">
            <Ban className="h-3.5 w-3.5" />
            Cancelled
          </Badge>
        </div>
      )}

      {isImmediateWaiting && (
        <div className="mt-4 flex flex-col gap-3 rounded-xl border-2 border-black bg-yellow-50 p-4">
          <div className="flex flex-col items-stretch gap-3 md:flex-row md:items-center md:justify-between">
            <Badge className={`rounded-full border-black ${isLive ? "bg-green text-black" : "bg-white text-black"}`}>
              {isLive ? "Live now" : "Wait time elapsed"}
            </Badge>
            <div className="flex flex-col gap-2 md:flex-row">
              <Button
                variant="neutral"
                size="sm"
                onClick={() => router.patch(`/users/pair_requests/${request.id}/extend_wait`)}
              >
                Keep waiting
              </Button>
              <Button
                variant="neutral"
                size="sm"
                onClick={() => setIsRescheduling((v) => !v)}
              >
                {isRescheduling ? "Never mind" : "Reschedule"}
              </Button>
            </div>
          </div>

          {isRescheduling && (
            <form onSubmit={submitReschedule} className="flex flex-col items-stretch gap-3">
              <PeriodPicker
                periods={rescheduleData.pair_request.periods_attributes}
                onChange={(periods) => setRescheduleData('pair_request', { periods_attributes: periods })}
              />
              <Button disabled={rescheduleProcessing} className="self-start">
                {rescheduleProcessing ? 'Rescheduling...' : 'Confirm reschedule'}
              </Button>
            </form>
          )}
        </div>
      )}

      {request.accepted_offer && (
        <div className="mt-5 rounded-xl border-2 border-black bg-green/10 p-4">
          <Badge className="mb-3 rounded-full border-black bg-green text-black uppercase tracking-widest">
            <CheckCircle2 className="h-3.5 w-3.5" />
            Matched
          </Badge>

          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-3">
              <Avatar className="h-11 w-11 shrink-0 border-2 border-black">
                <AvatarImage src={request.accepted_offer.offerer_image} alt={request.accepted_offer.offerer_name} />
                <AvatarFallback className="bg-orange text-white font-bold">{request.accepted_offer.offerer_name?.[0]}</AvatarFallback>
              </Avatar>
              <div>
                <p className="font-bold text-sm">{request.accepted_offer.offerer_name}</p>
                <span className="text-xs text-black/50">
                  {request.accepted_offer.offerer_profession}
                  {request.accepted_offer.offerer_profession && " · "}
                  {request.accepted_offer.offerer_level}
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-1 md:items-end">
              {request.sessions.map(s => (
                <div key={s.id} className="flex items-center gap-1.5">
                  <Badge variant="neutral" className="rounded-full text-xs">
                    {formatShort(s.start_at)}
                  </Badge>
                  <span className="text-black/30">→</span>
                  <Badge variant="neutral" className="rounded-full text-xs">
                    {formatShort(s.end_at)}
                  </Badge>
                </div>
              ))}
            </div>
          </div>

          <form onSubmit={submitCallLink} className="mt-4 flex flex-col items-stretch gap-2 md:flex-row md:items-end">
            <div className="flex flex-1 flex-col">
              <Label htmlFor="pair_request_sessions_attributes_0_call_link" className="mb-1">Call link</Label>
              <Input
                id="pair_request_sessions_attributes_0_call_link"
                type="text"
                value={data.pair_request.sessions_attributes[0]?.call_link}
                onChange={e => {
                  const newAttrs = [...data.pair_request.sessions_attributes];
                  newAttrs[0].call_link = e.target.value;
                  setData('pair_request', { ...data.pair_request, sessions_attributes: newAttrs });
                }}
                placeholder="https://meet.google.com/..."
                className="bg-white"
              />
            </div>
            <Button disabled={processing} className="md:w-32">
              {processing ? '...' : 'Add'}
            </Button>
          </form>
        </div>
      )}
    </div>
  );
}
