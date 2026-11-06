import { useState } from 'react';
import { Link, router } from '@inertiajs/react';
import { Inbox, CheckCircle2, Power, EyeOff, Share2, Pencil } from "lucide-react";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

const TAG_COLORS = ["bg-purple text-white", "bg-orange text-black", "bg-green text-black"];

function ShareLink({ path }) {
  const url = `${window.location.origin}${path}`;
  const [copied, setCopied] = useState(false);

  const copy = async (e) => {
    const field = e.currentTarget.previousElementSibling;
    field.select();
    try {
      await navigator.clipboard.writeText(url);
    } catch {
      // No clipboard access, such as on plain http: the link is selected to copy by hand.
      return;
    }
    setCopied(true);
  };

  return (
    <div className="mt-4 rounded-xl border-2 border-black bg-yellow-50 p-3">
      <Label htmlFor={`share_${path}`} className="mb-1 block">Send this to someone who might be a good partner</Label>
      <div className="flex gap-2">
        <Input id={`share_${path}`} readOnly value={url} onFocus={(e) => e.target.select()} className="bg-white" />
        <Button type="button" size="sm" onClick={copy}>{copied ? "Copied" : "Copy"}</Button>
      </div>
      <p className="mt-1 text-xs text-black/65">Anyone with this link can read this search and apply. It isn't listed on search engines.</p>
    </div>
  );
}

export default function UserPairRequestCard({ request }) {
  const [toggling, setToggling] = useState(false);
  const [sharing, setSharing] = useState(false);

  const toggleOnOff = () => {
    router.patch(`/users/pair_requests/${request.id}/${request.paused ? 'resume' : 'pause'}`, {}, {
      preserveScroll: true,
      onStart: () => setToggling(true),
      onFinish: () => setToggling(false),
    });
  };

  return (
    <div className={`mb-6 rounded-2xl border-2 border-black p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6 ${request.paused ? 'bg-black/5' : 'bg-white'}`}>
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <h3 className="text-xl">{request.subject}</h3>
        <div className="flex flex-wrap gap-2">
          <Button type="button" variant="neutral" size="sm" onClick={toggleOnOff} disabled={toggling} aria-pressed={!request.paused}>
            <Power className="h-4 w-4" />
            {request.paused ? 'Switch on' : 'Switch off'}
          </Button>
          {request.share_path && (
            <Button type="button" variant="neutral" size="sm" aria-expanded={sharing} onClick={() => setSharing(!sharing)}>
              <Share2 className="h-4 w-4" />
              Share
            </Button>
          )}
          <Button asChild variant="neutral" size="sm">
            <Link href={`/users/pair_requests/${request.id}/edit`}>
              <Pencil className="h-4 w-4" />
              Edit
            </Link>
          </Button>
          <Button asChild variant="neutral" size="sm">
            <Link href={`/pair_requests/${request.id}/offers`}>
              <Inbox className="h-4 w-4" />
              See applications
            </Link>
          </Button>
        </div>
      </div>

      {sharing && request.share_path && <ShareLink path={request.share_path} />}

      <Badge className="mt-3 rounded-full border-black bg-green text-xs text-black">Partner · {request.commitment_label}</Badge>

      {request.paused && (
        <Badge variant="neutral" className="ml-2 mt-3 rounded-full">
          <EyeOff className="h-3.5 w-3.5" />
          Off: hidden from others
        </Badge>
      )}

      <ExpandableText className="mt-3 leading-relaxed text-black/65">{request.description}</ExpandableText>

      <div className="mt-4 flex flex-wrap gap-2">
        {request.tags?.map((tag, i) => (
          <Badge key={tag.id} className={`rounded-full border-black ${TAG_COLORS[i % TAG_COLORS.length]}`}>
            {tag.name}
          </Badge>
        ))}
      </div>

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
                <AvatarFallback className="bg-orange text-black font-bold">{request.accepted_offer.offerer_name?.[0]}</AvatarFallback>
              </Avatar>
              <div>
                <p className="font-bold text-sm">{request.accepted_offer.offerer_name}</p>
                <span className="text-xs text-black/65">
                  {request.accepted_offer.offerer_profession}
                  {request.accepted_offer.offerer_profession && " · "}
                  {request.accepted_offer.offerer_level}
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
