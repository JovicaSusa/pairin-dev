import { Link, router } from "@inertiajs/react";
import { useState } from "react";
import logoImage from "@/assets/images/logo.svg";
import logoHamburger from "@/assets/images/hamburger.svg";
import { Button } from "@/components/ui/button";

export default function LandingNav({ user }) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <header className="w-full border-b-4 px-2 border-black bg-yellow-50 font-bold sticky top-0 z-10">
      <div className="flex flex-col max-w-screen-xl py-2 mx-auto md:items-center md:justify-between md:flex-row md:px-6 lg:px-8">
        <div className="flex items-center justify-between lg:justify-start">
          <div className="flex items-center justify-center space-x-2">
            <Link href="/" className="flex items-center gap-2">
              <img src={logoImage} alt="logo" className="h-8 w-8" />
              <span className="font-display text-xl font-extrabold tracking-tight">pairin</span>
            </Link>
          </div>

          <button onClick={() => setIsOpen(!isOpen)} className="rounded-lg md:hidden focus:outline-none focus:shadow-outline">
            <img src={logoHamburger} alt="menu" className="w-8 h-8 md:h-20" />
          </button>
        </div>

        <nav className={`flex-col flex-grow mt-4 md:flex md:justify-end md:flex-row ${ isOpen ? "flex" : "hidden" }`}>
          <ul className="space-y-2 list-none lg:space-y-0 lg:items-center lg:inline-flex">
            {user ? (
            <li>
              <Button size="sm" variant="neutral" onClick={() => router.delete('/users/sign_out')}>
                Logout
              </Button>
            </li>
            ) : (
              <>
                <li>
                  <a href="/users/sign_in" className="px-2 lg:px-6 py-6 text-sm border-b-2 border-transparent leading-[22px] md:px-3 text-black">
                    Login
                  </a>
                </li>
                <li>
                  <Button asChild size="sm">
                    <a href="/users/sign_up">Sign up</a>
                  </Button>
                </li>
              </>
            )}
          </ul>
        </nav>
      </div>
    </header>
  );
}
