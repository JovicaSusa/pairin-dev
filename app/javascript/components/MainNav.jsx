import { Link } from "@inertiajs/react";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import logoImg from "@/assets/images/logo.svg";
import hamburgerImg from "@/assets/images/hamburger.svg";

export default function MainNav({ currentUser, currentPath }) {
  const cleanPath = currentPath.split('?')[0];
  const isActive = (path) => cleanPath === path;

  const isPairRequestSubmenuActive = () => {
    return ['/users/pair_requests/new', '/users/pair_requests', '/users/offers'].includes(cleanPath);
  };

  const getLinkClasses = (path, isSubmenu = false) => {
    const baseClasses = "h-16 flex justify-center items-center cursor-pointer transition-all hover:translate-x-[3px] hover:translate-y-[3px]";
    const active = path ? isActive(path) : isPairRequestSubmenuActive();
    const activeClasses = active 
      ? "bg-purple text-white active" 
      : isSubmenu ? "hover:bg-orange bg-black/10" : "hover:bg-orange";
      
    return `${baseClasses} ${activeClasses}`;
  };

  return (
    <>
      {/* Desktop */}
      <aside className="hidden md:flex flex-col fixed h-screen w-2/12 font-sans bg-yellow-50 border-r-4 border-black border-dashed overflow-x-hidden z-40">
        <div className="flex-1 overflow-y-auto overflow-x-hidden">
          <div className="h-16 flex justify-center items-center border-b-4 border-black">
            <img src={logoImg} className="w-12 h-12" alt="Logo" />
          </div>

          <Link href="/pair_requests" className={`${getLinkClasses('/pair_requests')} border-b-4 border-black`}>
            Search
          </Link>

          <Collapsible defaultOpen={isPairRequestSubmenuActive()}>
            <CollapsibleTrigger asChild>
              <div className={`${getLinkClasses(null)} border-b-4 border-black font-bold`}>
                Pair Requests
              </div>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <Link href="/users/pair_requests/new" className={`${getLinkClasses('/users/pair_requests/new', true)} border-b-2 border-black`}>
                New
              </Link>
              <Link href="/users/pair_requests" className={`${getLinkClasses('/users/pair_requests', true)} border-b-2 border-black`}>
                Opened
              </Link>
              <Link href="/users/offers" className={`${getLinkClasses('/users/offers', true)} border-b-2 border-black`}>
                Applied
              </Link>
            </CollapsibleContent>
          </Collapsible>

          <Link href="/activities" className={`${getLinkClasses('/activities')} border-b-4 border-black`}>
            Feed
          </Link>

          <Link href="/sessions" className={`${getLinkClasses('/sessions')} border-b-4 border-black`}>
            Sessions
          </Link>
        </div>
        <div className="mt-auto border-t-4 border-black bg-yellow-50">
          <Collapsible>
            <CollapsibleTrigger asChild>
              <div className="w-full h-16 flex justify-center items-center cursor-pointer hover:bg-orange transition-all font-bold">
                Account
              </div>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <Link
                href={`/profiles/${currentUser.id}`}
                className="border-t-2 border-black h-16 flex justify-center items-center hover:bg-orange transition-all"
              >
                Profile
              </Link>
              <Link
                href="/users/sign_out"
                method="delete"
                as="button"
                className="w-full border-t-2 border-black h-16 flex justify-center items-center hover:bg-orange transition-all"
              >
                Log out
              </Link>
            </CollapsibleContent>
          </Collapsible>
        </div>
      </aside>

      {/* Mobile */}
      <div className="md:hidden sticky top-0 z-50 w-full bg-yellow-50 border-b-4 border-black h-16">
        <div className="relative h-full flex items-center px-4">
          <img src={logoImg} className="w-10 h-10" alt="Logo" />
          
          <Collapsible>
            <CollapsibleTrigger asChild>
              <button type="button" className="absolute top-1 right-2 p-1">
                <img src={hamburgerImg} className="w-8 h-8" alt="Menu" />
              </button>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <div className="absolute top-[60px] left-[-4px] w-[calc(100%+8px)] bg-yellow-50 border-b-4 border-black flex flex-col shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
                <Link href="/pair_requests" className={`${getLinkClasses('/pair_requests')} border-t-4 border-black`}>
                  Search
                </Link>

                <Collapsible defaultOpen={isPairRequestSubmenuActive()}>
                  <CollapsibleTrigger asChild>
                    <div className={`${getLinkClasses(null)} border-t-4 border-black font-bold`}>
                      Pair Requests
                    </div>
                  </CollapsibleTrigger>
                  <CollapsibleContent>
                    <Link href="/users/pair_requests/new" className={`${getLinkClasses('/users/pair_requests/new', true)} border-t-2 border-black`}>New</Link>
                    <Link href="/users/pair_requests" className={`${getLinkClasses('/users/pair_requests', true)} border-b-2 border-black`}>Opened</Link>
                    <Link href="/users/offers" className={`${getLinkClasses('/users/offers', true)} border-b-2 border-black`}>Applied</Link>
                  </CollapsibleContent>
                </Collapsible>

                <Link href="/activities" className={`${getLinkClasses('/activities')} border-t-4 border-black`}>Feed</Link>
                <Link href="/sessions" className={`${getLinkClasses('/sessions')} border-t-4 border-black`}>Sessions</Link>

                <Collapsible>
                  <CollapsibleTrigger asChild>
                    <div className="border-t-4 border-black h-16 flex justify-center items-center cursor-pointer hover:bg-orange font-bold">
                      Account
                    </div>
                  </CollapsibleTrigger>
                  <CollapsibleContent>
                    <Link href={`/profiles/${currentUser.id}`} className="border-t-2 border-black h-16 flex justify-center items-center hover:bg-orange">Profile</Link>
                    <Link href="/users/sign_out" method="delete" as="button" className="w-full border-t-2 border-black h-16 flex justify-center items-center hover:bg-orange">Log out</Link>
                  </CollapsibleContent>
                </Collapsible>
              </div>
            </CollapsibleContent>
          </Collapsible>
        </div>
      </div>
    </>
  );
}
