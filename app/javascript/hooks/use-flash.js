import { usePage } from '@inertiajs/react';
import { useEffect } from 'react';
import { toast } from 'sonner';

function showFlash(flash) {
  if (!flash) return;
  if (flash.notice) toast(flash.notice);
  if (flash.alert) toast.error(flash.alert);
  if (flash.error) toast.error(flash.error);
}

export function useFlash() {
  const { flash } = usePage();

  useEffect(() => {
    showFlash(flash);
  }, [flash]);
}
