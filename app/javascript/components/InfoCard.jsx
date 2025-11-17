export default function InfoCard({ alt, image, title, text }) {

  return (
    <div className="md:w-2/3 border-2 border-black flex bg-white h-[460px] pb-4 flex-col items-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <div className="w-full border-b-2 border-black p-4 font-bold text-center bg-purple">
        <h2 className="text-lg font-headline">{title}</h2>
      </div>

      <div className="h-2/6 md:h-3/6 mt-6 flex justify-center items-center">
        <img src={image} alt={alt} className="w-1/2 h-fit" />
      </div>

      <div className="pt-4 pb-2 flex mt-6 px-2 md:px-4">
        <p className="text-center text-xl md:text-base">{text}</p>
      </div>
    </div>
  );
}
