// What a thread and a Workspace share.
import { router, useForm } from "@inertiajs/react";
import { useState } from "react";
import { Send } from "lucide-react";
import { formatShort } from "@/helpers/date";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

// Small text actions keep their look on phones, but get a full-size tap area.
export const TAP_AREA = "inline-flex min-h-11 items-center md:min-h-0";

export function Face({ person }) {
  return (
    <Avatar className="h-10 w-10 shrink-0 border-2 border-black">
      <AvatarImage src={person.image_url} alt={person.name} />
      <AvatarFallback className="bg-orange font-bold text-black">{person.name?.[0]}</AvatarFallback>
    </Avatar>
  );
}

// The older messages fade in an ended chat. A message from Pairin says why, so it never does.
export function Messages({ messages, dim = false }) {
  return (
    <div className="flex flex-col gap-3">
      {messages.map((m) => m.from_pairin ? (
        <p key={m.id} className="mx-auto max-w-[85%] text-center text-sm font-bold">{m.body}</p>
      ) : (
        <div key={m.id} className={`flex flex-col ${m.mine ? "items-end" : "items-start"} ${dim ? "opacity-70" : ""}`}>
          <p className={`max-w-[85%] whitespace-pre-wrap break-words rounded-2xl border-2 border-black px-3 py-2 text-sm ${m.mine ? "bg-purple text-white" : "bg-white"}`}>
            {m.body}
          </p>
          <span className="mt-0.5 text-xs text-black/65">{formatShort(m.at)}</span>
        </div>
      ))}
    </div>
  );
}

export function Composer({ conversation }) {
  const { data, setData, post, processing, errors, reset } = useForm({ message: { body: "" } });
  const firstReply = conversation.viewer_is_poster && !conversation.chat_open;

  const send = (e) => {
    e.preventDefault();
    if (processing || !data.message.body.trim()) return;
    post(`/conversations/${conversation.id}/messages`, { preserveScroll: true, onSuccess: () => reset() });
  };

  // Enter sends and Shift+Enter starts a new line. On a touch keyboard Enter is
  // the only way to start a new line, and there's a Send button in reach.
  const onKeyDown = (e) => {
    const touch = window.matchMedia("(pointer: coarse)").matches;
    if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing && !touch) send(e);
  };

  return (
    <form onSubmit={send}>
      <div className="flex items-end gap-2">
        <Textarea
          rows={2}
          aria-label="Write a message"
          placeholder={firstReply ? `Reply to ${conversation.other.name} to start chatting` : "Write a message"}
          value={data.message.body}
          onChange={(e) => setData("message", { body: e.target.value })}
          onKeyDown={onKeyDown}
          className="min-h-10 flex-1"
        />
        <Button type="submit" disabled={processing || !data.message.body.trim()} aria-label="Send">
          <Send />
        </Button>
      </div>
      {errors.body && <div className="mt-1 text-sm font-bold text-red">{errors.body}</div>}
      {firstReply && <p className="mt-1 text-xs text-black/65">Replying isn't a commitment. It just starts the conversation.</p>}
    </form>
  );
}

export function ReportForm({ conversation, onDone }) {
  const { data, setData, post, processing, errors } = useForm({ reason: "" });

  const submit = (e) => {
    e.preventDefault();
    post(`/conversations/${conversation.id}/report`, { preserveScroll: true, onSuccess: onDone });
  };

  return (
    <form onSubmit={submit} aria-label="Report" className="border-b-2 border-black bg-yellow-50 p-3">
      <p className="text-sm font-bold">Report {conversation.other.name}</p>
      <p className="mb-2 text-xs text-black/65">
        The Pairin team will see your reason and your recent messages here, and may read this chat. {conversation.other.name} won't be told.
      </p>
      <Label htmlFor="report_reason" className="mb-1 block text-xs">What happened?</Label>
      <Textarea id="report_reason" rows={2} value={data.reason} onChange={(e) => setData("reason", e.target.value)} />
      {errors.reason && <div className="mt-1 text-sm font-bold text-red">{errors.reason}</div>}
      <div className="mt-2 flex gap-2">
        <Button type="submit" size="sm" disabled={processing}>Send report</Button>
        <Button type="button" size="sm" variant="neutral" onClick={onDone}>Cancel</Button>
      </div>
    </form>
  );
}

export function BlockConfirmation({ conversation, onCancel, consequence = "This ends your conversations, and neither of you will see or apply to the other's partner searches." }) {
  const [processing, setProcessing] = useState(false);

  const block = () => {
    router.post(`/conversations/${conversation.id}/block`, {}, {
      preserveScroll: true,
      onStart: () => setProcessing(true),
      onFinish: () => setProcessing(false),
    });
  };

  return (
    <div role="group" aria-label="Confirm block" className="border-b-2 border-black bg-yellow-50 p-3">
      <p className="text-sm font-bold">Block {conversation.other.name}?</p>
      <p className="mb-2 text-xs text-black/65">
        {consequence} {conversation.other.name} won't be told you blocked them.
      </p>
      <div className="flex gap-2">
        <Button type="button" size="sm" disabled={processing} onClick={block}>Block</Button>
        <Button type="button" size="sm" variant="neutral" onClick={onCancel}>Cancel</Button>
      </div>
    </div>
  );
}
