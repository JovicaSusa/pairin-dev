import MainNav from "@/components/MainNav";
import { Toaster } from "@/components/ui/sonner";
import { useFlash } from "@/hooks/use-flash";
import { usePage } from '@inertiajs/react';

export default function AppLayout({ children }) {
  const { url, props } = usePage();
  const currentUser = props.auth?.user;
  useFlash();

  return (
    <main className='relative bg-yellow-50 min-h-screen pt-8 md:pt-0'>
      <Toaster position="top-center" />
      <MainNav currentUser={currentUser} currentPath={url} />
      <article className="md:ml-[16.666667%] min-h-screen">{children}</article>
    </main>
  );
}
