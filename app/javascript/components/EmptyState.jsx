export default function EmptyState({ icon: Icon, title, description, children }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-2xl border-2 border-black bg-white px-8 py-16 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      {Icon && (
        <div className="mb-1 flex h-12 w-12 items-center justify-center rounded-xl border-2 border-black bg-yellow-50">
          <Icon className="h-6 w-6 text-black/60" strokeWidth={2} />
        </div>
      )}
      <p className="text-lg font-bold">{title}</p>
      {description && <p className="max-w-sm text-black/50">{description}</p>}
      {children}
    </div>
  );
}
