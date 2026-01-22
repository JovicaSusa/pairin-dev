import FlashMessages from '@/components/FlashMessages';
import MainNav from "@/components/MainNav";
import { usePage } from '@inertiajs/react';

export default function AppLayout({ children }) {
  const { url, props } = usePage()
  const currentUser = props.auth?.user;

  return (
    <main className='relative bg-yellow-50 min-h-screen px-4 pt-8 md:pt-0'>
      <FlashMessages />
      <MainNav currentUser={currentUser} currentPath={url} />
      <article className="md:ml-[16.666667%] min-h-screen">{children}</article>
    </main>
  );
}
