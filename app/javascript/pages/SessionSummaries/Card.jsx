import ExpandableText from "@/components/ExpandableText";
import { Badge } from "@/components/ui/badge";

const TAG_COLORS = ["bg-purple text-white", "bg-orange text-white", "bg-green text-black"];

const WENT_WELL_EMOJI = {
  great: "🎉",
  good: "🙂",
  okay: "😐",
  tough: "😓",
};

export default function SessionSummaryCard({ sessionSummary }) {
  const feedbacks = sessionSummary.session_feedbacks ?? [];

  return (
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <h3 className="text-xl">{sessionSummary.subject}</h3>

      <ExpandableText className="mt-3 leading-relaxed text-black/60">{sessionSummary.description}</ExpandableText>

      {sessionSummary.goal && (
        <p className="mt-3 text-sm text-black/60"><span className="font-bold text-black">Goal:</span> {sessionSummary.goal}</p>
      )}

      {sessionSummary.platform && (
        <p className="mt-1 text-sm text-black/60"><span className="font-bold text-black">Platform:</span> {sessionSummary.platform}</p>
      )}

      {sessionSummary.plan && (
        <p className="mt-1 text-sm text-black/60"><span className="font-bold text-black">Plan:</span> {sessionSummary.plan}</p>
      )}

      <div className="mt-4 flex flex-wrap gap-2">
        {sessionSummary.tags.map((tag, i) => (
          <Badge key={tag.id} className={`rounded-full border-black ${TAG_COLORS[i % TAG_COLORS.length]}`}>
            {tag.name}
          </Badge>
        ))}
      </div>

      {feedbacks.length > 0 && (
        <div className="mt-5 grid gap-4 border-t-2 border-black/10 pt-4 md:grid-cols-2">
          {feedbacks.map((feedback) => (
            <div key={feedback.participant.id} className="rounded-xl border-2 border-black/10 p-3">
              <p className="font-bold text-sm">
                {WENT_WELL_EMOJI[feedback.went_well]} {feedback.participant.name}
              </p>
              {feedback.learned && (
                <p className="mt-1 text-sm text-black/60"><span className="font-bold text-black">Learned:</span> {feedback.learned}</p>
              )}
              {feedback.notes && (
                <p className="mt-1 text-sm text-black/60"><span className="font-bold text-black">Notes:</span> {feedback.notes}</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
