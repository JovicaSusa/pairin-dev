import MainNav from "@/components/MainNav";
import { Toaster } from "@/components/ui/sonner";
import { useFlash } from "@/hooks/use-flash";
import { usePage } from '@inertiajs/react';
import { useEffect } from 'react';

export default function AppLayout({ children }) {
  const { url, props } = usePage();
  const currentUser = props.auth?.user;
  useFlash();

  useEffect(() => {
    const observer = new MutationObserver(() => {
      if (document.body.hasAttribute('data-scroll-locked')) {
        document.body.style.setProperty('margin-right', '0', 'important');
      } else {
        document.body.style.removeProperty('margin-right');
      }
    });
    observer.observe(document.body, { attributes: true, attributeFilter: ['data-scroll-locked'] });
    return () => observer.disconnect();
  }, []);

  return (
    <main className='relative bg-yellow-50 min-h-screen'>
      <Toaster position="top-center" />
      <MainNav currentUser={currentUser} currentPath={url} />
      <article className="min-h-screen md:ml-64">{children}</article>
    </main>
  );
}
