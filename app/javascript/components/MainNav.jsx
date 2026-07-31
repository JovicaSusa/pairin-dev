import { Link } from "@inertiajs/react";
import { useEffect, useState } from "react";
import {
  Search,
  ClipboardList,
  FilePlus2,
  Inbox,
  Send,
  Rss,
  CalendarClock,
  ChevronDown,
  LogOut,
  Menu,
  X,
} from "lucide-react";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import logoImg from "@/assets/images/logo.svg";

const NAV_ITEMS = [
  { href: "/pair_requests", label: "Search", icon: Search },
  { href: "/activities", label: "Feed", icon: Rss },
  { href: "/sessions", label: "Sessions", icon: CalendarClock },
];

const PAIR_REQUEST_SUBMENU = [
  { href: "/users/pair_requests/new", label: "New", icon: FilePlus2 },
  { href: "/users/pair_requests", label: "Opened", icon: Inbox },
  { href: "/users/offers", label: "Applied", icon: Send },
];

function NavLink({ href, label, icon: Icon, active, small = false, onClick }) {
  return (
    <Link
      href={href}
      onClick={onClick}
      className={`flex items-center gap-3 rounded-xl border-2 font-headline font-bold transition-all ${
        small ? "px-3 py-2 text-sm" : "px-3 py-2.5 text-sm"
      } ${
        active
          ? "border-black bg-purple text-white shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
          : "border-transparent text-black hover:border-black hover:bg-yellow-50 hover:translate-x-[1px] hover:translate-y-[1px]"
      }`}
    >
      {Icon && <Icon className="h-[18px] w-[18px] shrink-0" strokeWidth={2.25} />}
      <span className="truncate">{label}</span>
    </Link>
  );
}

function NavContent({ currentPath, currentUser, onNavigate }) {
  const cleanPath = currentPath.split("?")[0];
  const isActive = (path) => cleanPath === path;
  const isPairRequestSubmenuActive = () => PAIR_REQUEST_SUBMENU.some((item) => item.href === cleanPath);
  const isProfileActive = () => cleanPath === `/profiles/${currentUser.id}`;

  return (
    <>
      <div className="flex items-center gap-2 border-b-2 border-black px-5 py-5">
        <img src={logoImg} className="h-8 w-8" alt="Pairin" />
        <span className="font-display text-xl font-extrabold tracking-tight">pairin</span>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-4">
        <div className="flex flex-col gap-1">
          <NavLink {...NAV_ITEMS[0]} active={isActive(NAV_ITEMS[0].href)} onClick={onNavigate} />

          <Collapsible defaultOpen={isPairRequestSubmenuActive()}>
            <CollapsibleTrigger asChild>
              <button
                type="button"
                className={`group flex w-full items-center gap-3 rounded-xl border-2 px-3 py-2.5 font-headline font-bold text-sm transition-all ${
                  isPairRequestSubmenuActive()
                    ? "border-black bg-purple/10 text-purple"
                    : "border-transparent text-black hover:border-black hover:bg-yellow-50 hover:translate-x-[1px] hover:translate-y-[1px]"
                }`}
              >
                <ClipboardList className="h-[18px] w-[18px] shrink-0" strokeWidth={2.25} />
                <span className="flex-1 text-left truncate">Pair Requests</span>
                <ChevronDown className="h-4 w-4 shrink-0 transition-transform group-data-[state=open]:rotate-180" />
              </button>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <div className="relative mt-1 ml-5 flex flex-col gap-1 border-l-2 border-black/15 pl-4">
                {PAIR_REQUEST_SUBMENU.map((item) => (
                  <NavLink key={item.href} {...item} active={isActive(item.href)} small onClick={onNavigate} />
                ))}
              </div>
            </CollapsibleContent>
          </Collapsible>

          <NavLink {...NAV_ITEMS[1]} active={isActive(NAV_ITEMS[1].href)} onClick={onNavigate} />
          <NavLink {...NAV_ITEMS[2]} active={isActive(NAV_ITEMS[2].href)} onClick={onNavigate} />
        </div>
      </nav>

      <div className="border-t-2 border-black p-3">
        <Link
          href={`/profiles/${currentUser.id}`}
          onClick={onNavigate}
          className={`flex items-center gap-3 rounded-xl border-2 px-3 py-2.5 transition-all ${
            isProfileActive()
              ? "border-black bg-purple text-white shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              : "border-transparent hover:border-black hover:bg-yellow-50 hover:translate-x-[1px] hover:translate-y-[1px]"
          }`}
        >
          <Avatar className="h-9 w-9 shrink-0 border-2 border-black">
            <AvatarImage src={currentUser.image_url} alt={currentUser.name} />
            <AvatarFallback className="bg-orange text-white font-display font-bold">
              {currentUser.name?.[0]}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1">
            <p className="truncate font-headline font-bold text-sm leading-tight">{currentUser.name || "Your profile"}</p>
            <span className={`text-xs ${isProfileActive() ? "text-white/70" : "text-black/50"}`}>View profile</span>
          </div>
        </Link>

        <Link
          href="/users/sign_out"
          method="delete"
          as="button"
          onClick={onNavigate}
          className="mt-1 flex w-full items-center gap-3 rounded-xl border-2 border-transparent px-3 py-2 font-headline font-bold text-sm text-black/60 transition-all hover:border-black hover:bg-red/10 hover:text-red"
        >
          <LogOut className="h-[18px] w-[18px] shrink-0" strokeWidth={2.25} />
          Log out
        </Link>
      </div>
    </>
  );
}

export default function MainNav({ currentUser, currentPath }) {
  const [drawerOpen, setDrawerOpen] = useState(false);

  useEffect(() => {
    if (!drawerOpen) return;
    const onKeyDown = (e) => e.key === "Escape" && setDrawerOpen(false);
    document.addEventListener("keydown", onKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
    };
  }, [drawerOpen]);

  return (
    <>
      {/* Desktop sidebar */}
      <aside className="hidden md:fixed md:inset-y-0 md:left-0 md:z-40 md:flex md:w-64 md:flex-col md:border-r-2 md:border-black md:bg-white">
        <NavContent currentPath={currentPath} currentUser={currentUser} />
      </aside>

      {/* Mobile top bar */}
      <div className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b-2 border-black bg-white px-4 md:hidden">
        <Link href="/pair_requests" className="flex items-center gap-2">
          <img src={logoImg} className="h-8 w-8" alt="Pairin" />
          <span className="font-display text-lg font-extrabold tracking-tight">pairin</span>
        </Link>
        <button
          type="button"
          onClick={() => setDrawerOpen(true)}
          aria-label="Open menu"
          className="flex h-10 w-10 items-center justify-center rounded-xl border-2 border-black bg-white transition-all hover:translate-x-[1px] hover:translate-y-[1px] active:shadow-none"
        >
          <Menu className="h-5 w-5" />
        </button>
      </div>

      {/* Mobile drawer */}
      <div
        className={`fixed inset-0 z-50 md:hidden ${drawerOpen ? "pointer-events-auto" : "pointer-events-none"}`}
        aria-hidden={!drawerOpen}
      >
        <div
          onClick={() => setDrawerOpen(false)}
          className={`absolute inset-0 bg-black/50 transition-opacity duration-300 ${
            drawerOpen ? "opacity-100" : "opacity-0"
          }`}
        />
        <div
          className={`absolute inset-y-0 left-0 flex w-72 max-w-[80%] flex-col border-r-2 border-black bg-white shadow-[8px_0px_0px_0px_rgba(0,0,0,1)] transition-transform duration-300 ease-in-out ${
            drawerOpen ? "translate-x-0" : "-translate-x-full"
          }`}
        >
          <button
            type="button"
            onClick={() => setDrawerOpen(false)}
            aria-label="Close menu"
            className="absolute right-3 top-3 flex h-9 w-9 items-center justify-center rounded-xl border-2 border-black bg-white"
          >
            <X className="h-4 w-4" />
          </button>
          <NavContent currentPath={currentPath} currentUser={currentUser} onNavigate={() => setDrawerOpen(false)} />
        </div>
      </div>
    </>
  );
}
