import { usePage } from '@inertiajs/react';
import { useState, useEffect } from 'react';

export default function FlashMessages() {
  const { flash } = usePage().props;
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const hasMessage = flash && Object.values(flash).some(val => val !== null && val !== '');
    
    if (hasMessage) {
      setVisible(true);
      const timer = setTimeout(() => setVisible(false), 5000);
      return () => clearTimeout(timer);
    } else {
      setVisible(false);
    }
  }, [flash]);

  if (!visible) return null;

  return (
    <div className="absolute w-full z-[100] flex flex-col gap-2">
      {Object.entries(flash).map(([type, message]) => (
        message && (
          <div key={type} className="flex items-center justify-center border-2 border-black bg-purple p-5 px-8 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] animate-appearThenFade">
            {message}
          </div>
        )
      ))}
    </div>
  );
}
