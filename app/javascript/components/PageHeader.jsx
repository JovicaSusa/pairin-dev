export default function PageHeader({ eyebrow, title, description, action }) {
  return (
    <div className="mb-8 mt-8 flex flex-col gap-5 md:mt-10 md:mb-10 md:flex-row md:items-end md:justify-between">
      <div>
        {eyebrow && (
          <span className="mb-2 block text-xs font-bold uppercase tracking-widest text-purple">{eyebrow}</span>
        )}
        <h1 className="text-3xl leading-tight md:text-4xl">{title}</h1>
        {description && <p className="mt-2 max-w-lg text-black/50">{description}</p>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
}
