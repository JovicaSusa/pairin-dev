import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

export default function InfoCard({ alt, image, title, text }) {
  return (
    <Card className="md:w-2/3 h-[460px] items-center bg-white gap-0 py-0 pb-4">
      <CardHeader className="w-full flex justify-center items-center border-b-2 border-border bg-purple p-4 rounded-t-base">
        <CardTitle className="text-lg font-headline text-center">{title}</CardTitle>
      </CardHeader>

      <div className="h-2/6 md:h-3/6 mt-6 flex justify-center items-center">
        <img src={image} alt={alt} className="w-1/2 h-fit" />
      </div>

      <CardContent className="pt-4 pb-2 flex mt-6 px-2 md:px-4">
        <p className="text-center text-xl md:text-base">{text}</p>
      </CardContent>
    </Card>
  )
}
