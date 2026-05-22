import InfoCard from "@/components/InfoCard";
import LandingNav from "@/components/LandingNav";
import { Toaster } from "@/components/ui/sonner";
import { useFlash } from "@/hooks/use-flash";
import { Button } from "@/components/ui/button";
import collaborateImage from "@/assets/images/collaborate.svg";
import arrowImage from "@/assets/images/arrow.svg"
import logoImage from "@/assets/images/logo.svg";
import startImage from "@/assets/images/start.svg";
import searchNewImg from "@/assets/images/search_new.svg";
import offerImg from "@/assets/images/offer.svg";
import awaitImg from "@/assets/images/await.svg";
import postNewImg from "@/assets/images/post_new.svg";
import reviewImg from "@/assets/images/review.svg";
import acceptImg from "@/assets/images/accept.svg";

export default function Home({ auth }) {
  useFlash();

  return (
    <div>
      <Toaster position="top-center" />
      <LandingNav user={auth.user} />
      <div className="w-full flex justify-center">
        <div className="flex w-full md:w-1/2 justify-center px-5 py-12 md:px-12 lg:px-16 lg:py-24">
          <div className="text-center">
            <div className="font-headline">
              <span className="text-6xl font-bold">It's</span>
              <span className="block font-bold bg-orange text-8xl px-4 font-headline">
                PAIRIN
              </span>
              <span className="text-6xl font-bold">time!</span>
            </div>
            <div className="border-b-4 pb-2 border-black border-dashed">
              <h1 className="mt-4 text-xl tracking-wide">
                Find pair programming partner or coding buddy quick and easy!
              </h1>
            </div>

            <div className="flex justify-center w-full max-w-2xl gap-2 mt-12">
              <div className="mt-3 sm:mt-0">
                <Button asChild size="lg" className="font-headline text-2xl md:text-base">
                  <a href="/users/sign_up">Sign Up Now</a>
                </Button>
              </div>
              <div className="hidden md:block mt-3 sm:mt-0 sm:ml-3">
                <Button asChild size="lg" variant="neutral" className="font-headline">
                  <a href="#how-it-works">Show me more</a>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="relative flex w-full overflow-x-hidden border-b-8 border-t-2 border-black bg-green font-bold">
        <div className="animate-marquee whitespace-nowrap py-12 flex">
          {[
            "rails-plain-wordmark",
            "c-plain",
            "clojure-line",
            "csharp-plain",
            "css3-plain",
            "docker-plain",
            "dot-net-plain",
            "flutter-plain",
            "go-original-wordmark",
            "javascript-plain",
            "kotlin-plain",
            "kubernetes-plain",
            "ruby-plain",
            "rust-plain",
          ].map((icon) => (
            <span
              key={icon}
              className="flex justify-center items-center bg-orange border-2 border-black rounded-xl block w-16 h-16 md:w-24 md:h-24 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] mx-4 text-4xl"
            >
              <i className={`devicon-${icon}`}></i>
            </span>
          ))}
        </div>
      </div>

      <div className="w-full flex flex-col items-center mt-12 md:mt-24">
        <div className="md:w-1/2 text-center">
          <h2 className="font-bold text-5xl md:text-6xl font-headline uppercase">
            Look no further!
          </h2>
          <p className="mt-4 px-8 md:px-0">
            <span className="font-semibold">Pairin.dev</span> is a community of
            programmers connecting with others for pair programming or coding
            collaboration. Whether you need a coding buddy or a pair programming
            partner, you'll find the right match here.
          </p>
        </div>

        <img
          src={collaborateImage}
          alt="Programmers collaborating"
          className="w-1/2 md:w-1/4 h-fit mt-8"
        />
      </div>

      <div
        id="how-it-works"
        className="flex items-center flex-col relative bg-yellow-50 pb-24"
      >
        <div className="relative text-center">
          <h2 className="relative uppercase mt-16 md:mt-24 font-bold text-5xl px-6 py-6 md:text-6xl font-headline">
            How it works?
          </h2>

          <div className="max-sm:hidden absolute -bottom-8 -left-16">
            <img
              src={arrowImage}
              alt="Arrow"
              className="relative w-16 h-16 -scale-x-100 rotate-45"
            />
            <span className="block absolute top-0 -left-2 -rotate-45 text-md">do this</span>
          </div>
          <div className="max-sm:hidden absolute -bottom-8 -right-16">
            <img
              src={arrowImage}
              alt="Arrow"
              className="relative w-16 h-16 -rotate-45"
            />
            <span className="absolute top-0 -right-2 rotate-45 text-md">or this</span>
          </div>          
        </div>

        <div className="grid w-full md:grid-cols-2 mt-16 px-4">
          <div className="flex gap-y-12 flex-col items-center relative md:border-r-4 md:border-black md:border-dashed">
            <InfoCard
              alt="Programmer searching for pair programming partners"
              image={searchNewImg}
              title="Search for Pairing Opportunities"
              text="Discover pair programming requests from our vibrant community. Customize your search by technology, time availability, or desired experience level to find the perfect match."
            />
            <InfoCard
              alt="Programmer applying for pair programming"
              image={offerImg}
              title="Express Your Interest"
              text="Once you've found a pairing request that aligns with your preferences, choose your availability and reach out to the requester. Craft a compelling message to increase your chances of being accepted as a programming partner."
            />
            <InfoCard
              alt="Programmer waiting for outcome of pair programming application"
              image={awaitImg}
              title="Await Approval"
              text="After expressing your interest and sending out your application, patiently await approval from the requester. During this time, feel free to prepare for the upcoming pair programming session and stay connected with our community."
            />
            <img
              src={arrowImage}
              alt="Arrow"
              className="absolute -bottom-32 right-50 w-24 h-24 -scale-x-100 invisible md:visible"
            />
          </div>

          <div className="flex flex-col gap-y-12 items-center relative">
            <InfoCard
              alt="Programmer posting new pair programming request"
              image={postNewImg}
              title="Post your pair programming request"
              text="Share your coding project or learning goals by posting a pair programming request. Let us know your preferred tech, when you're free, and what you're looking for in a coding partner."
            />
            <InfoCard
              alt="Programmer reviewing pair programming request applications"
              image={reviewImg}
              title="Review Received Applications"
              text="Your request is live, and applications are coming in. Take some time to review profiles and find the right match for your project. The perfect coding companion is just around the corner."
            />
            <InfoCard
              alt="Programmer accepting pair programming application"
              image={acceptImg}
              title="Accept one of the applications"
              text="Review applications and choose the one that fits your project. Confirm your coding teammate and get ready to start working together. It's as simple as that!"
            />
            <img
              src={arrowImage}
              alt="Arrow"
              className="absolute -bottom-32 right-50 w-24 h-24 invisible md:visible"
            />
          </div>
        </div>

        <h2 className="mt-16 md:mt-24 text-6xl font-bold ">Start pairin!</h2>
        <div className="w-full flex justify-center mt-12">
          <img
            src={startImage}
            alt="Programmer on the road to success with pair programming"
            className="block w-80 h-80 md:h-96 md:w-96"
          />
        </div>

        <div className="flex flex-col px-4 md:px-0 mt-24 md:mt-44 items-center">
          <div className="text-center md:w-1/3">
            <h1 className="text-4xl md:text-6xl font-headline font-bold uppercase">
              Meet our members
            </h1>
            <p className="mt-8 md:mt-12 tracking-wide text-xl md:text-base">
              We're currently in the beta phase, and our community is in its
              early stages of growth. You can help us by becoming one of our
              inaugural members. Join now to be part of the foundation and help
              shape the future of our community!
            </p>
          </div>

          <Button asChild size="lg" className="font-headline text-2xl md:text-base mt-12 md:mt-16">
            <a href="/users/sign_up">Join our community</a>
          </Button>
        </div>
      </div>

      <div className="flex h-40 w-full border-black bg-white border-t-4 font-bold">
        <div className="w-1/2 flex flex-col items-center mt-6">
          <div>
            <p className="font-headline">Start pairin</p>
            <p>
              <a href="/users/sign_up">Sign up</a>
            </p>
            <p>
              <a href="/users/sign_in">Log in</a>
            </p>
          </div>
        </div>
        <div className="flex flex-col w-1/2 mt-2 items-center">
          <img src={logoImage} alt="Pairin.dev logo" className="w-24 h-24" />
          <span className="block text-sm">made by Manufaktura Koda</span>
        </div>
      </div>
    </div>
  );
}
