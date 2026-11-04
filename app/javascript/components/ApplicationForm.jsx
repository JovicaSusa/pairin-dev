import { useForm } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const FieldError = ({ message }) =>
  message ? <div className="mt-1 text-sm font-bold text-red">{message}</div> : null;

function Choice({ id, label, value, options, onChange, error }) {
  return (
    <div>
      <Label className="mb-1 block">{label}</Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger id={id} className="w-full" aria-label={label}>
          <SelectValue placeholder="Choose one" />
        </SelectTrigger>
        <SelectContent>
          {options.map((option) => (
            <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>
      <FieldError message={error} />
    </div>
  );
}

// The poster's name, the search's commitment and the answers. Used in the drawer
// on the list and on the full page that links in emails open.
export default function ApplicationForm({ pairRequest, options, needsLevel, onSuccess, viaShareLink = false }) {
  const posterName = pairRequest.user.name || "the poster";
  const { data, setData, post, processing, errors } = useForm({
    offer: { goal: "", how_often: "", how_long: "", message: "", level: "", via_share_link: viaShareLink },
  });

  const field = (name) => ({
    value: data.offer[name],
    onChange: (value) => setData("offer", { ...data.offer, [name]: value }),
    error: errors[name],
  });

  const submit = (e) => {
    e.preventDefault();
    post(`/pair_requests/${pairRequest.id}/offers`, { preserveScroll: true, preserveState: true, onSuccess });
  };

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <div>
        <Label htmlFor="application_goal" className="mb-1 block">What do you want to get out of this?</Label>
        <Textarea
          id="application_goal"
          rows="2"
          autoFocus
          value={data.offer.goal}
          onChange={(e) => field("goal").onChange(e.target.value)}
        />
        <FieldError message={errors.goal} />
      </div>

      <Choice id="application_how_often" label="How often can you pair?" options={options.howOften} {...field("how_often")} />
      <div>
        <Choice id="application_how_long" label="How long can you commit?" options={options.howLong} {...field("how_long")} />
        <p className="mt-1 text-xs text-black/50">{posterName} is looking for: {pairRequest.commitment_label}</p>
      </div>

      {needsLevel && (
        <div>
          <Choice id="application_level" label="Your level" options={options.levels} {...field("level")} />
          <p className="mt-1 text-xs text-black/50">We'll save this to your profile, so we only ask once.</p>
        </div>
      )}

      <div>
        <Label htmlFor="application_message" className="mb-1 block">Your message to {posterName}</Label>
        <Textarea
          id="application_message"
          rows="3"
          value={data.offer.message}
          onChange={(e) => field("message").onChange(e.target.value)}
        />
        <FieldError message={errors.message} />
      </div>

      <Button type="submit" size="lg" disabled={processing} className="mt-2 w-full">
        {processing ? "Sending..." : "Send application"}
      </Button>
    </form>
  );
}
