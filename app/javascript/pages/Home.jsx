import { Head, Link } from "@inertiajs/react";
import LandingNav from "@/components/LandingNav";
import { Toaster } from "@/components/ui/sonner";
import { useFlash } from "@/hooks/use-flash";
import { Button } from "@/components/ui/button";
import collaborateImage from "@/assets/images/collaborate.svg";
import startImage from "@/assets/images/start.svg";
import logoImage from "@/assets/images/logo.svg";

const TECH_ICONS = [
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
  "python-plain",
  "typescript-plain",
  "vuejs-plain",
  "react-original",
];

const LIVE_NOW = [
  { name: "Alex M.", emoji: "🧑‍💻", tags: ["React", "TypeScript"], level: "Mid-level" },
  { name: "Sara K.", emoji: "👩‍💻", tags: ["Python", "Django"], level: "Senior" },
  { name: "Luca R.", emoji: "🧑‍💻", tags: ["Rails", "PostgreSQL"], level: "Junior" },
];

const ABOUT_CHIPS = ["Match by tech stack", "Set experience level", "All levels welcome"];

const LIVE_NOW_STEPS = [
  {
    title: "Go live",
    text: "Post what you want to work on right now and how long you're willing to wait. You'll show up in the live list immediately.",
  },
  {
    title: "Get matched instantly",
    text: "Someone joins your request and the session starts right away — no approval needed, unless you've asked to review joiners first.",
  },
];

const SCHEDULED_STEPS = [
  {
    title: "Post a request for later",
    text: "Share your project or learning goal. Specify your stack, when you're free, and what you're looking for in a partner.",
  },
  {
    title: "Review applications",
    text: "Browse who applied and pick the right fit for your project. Compare their stack and experience before you choose.",
  },
  {
    title: "Confirm & await approval",
    text: "Approve the applicant you like best, or wait for confirmation if you applied. You're locked in — session details go to both of you.",
  },
];

const FEATURES = [
  { iconBg: "bg-green/10", icon: "⚡", title: "Real-time list", body: "See who's online and ready to pair, right now." },
  { iconBg: "bg-purple/10", icon: "🎛️", title: "Stay in control", body: "Keep waiting, reschedule for later, or cancel your live request any time before someone joins." },
  { iconBg: "bg-orange/10", icon: "📝", title: "Reflect after", body: "Once a session wraps, leave a quick retro — what went well, what you learned, and any code worth sharing." },
  { iconBg: "bg-green/10", icon: "📚", title: "Browse real sessions", body: "See what other members worked on and learned from their retros — real examples, once you're signed in." },
];

const FAQS = [
  { q: "What is Pairin?", a: "Pairin is a community of developers connecting for pair programming and collaboration. Post what you're working on or browse live requests, and pair with another developer in minutes." },
  { q: "Is Pairin free to use?", a: "Yes. Pairin is completely free during its beta period — sign up and start pairing at no cost." },
  { q: "How do I find a pairing partner?", a: "Go live to get matched instantly with someone free right now, or post a request for later, review who applies, and confirm the session that fits best." },
  { q: "What tech stacks does Pairin support?", a: "Pairin supports developers across all major stacks and experience levels, including Ruby, Rails, Python, JavaScript, TypeScript, Go, and Rust. Match by tech stack and experience level." },
  { q: "Do I need to schedule a session in advance?", a: "No. You can go live for an instant match or post a request and schedule a session for later, whichever fits your schedule." },
];

const FAQ_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQS.map((faq) => ({
    "@type": "Question",
    name: faq.q,
    acceptedAnswer: { "@type": "Answer", text: faq.a },
  })),
};

function StepCard({ number, title, text, accent }) {
  return (
    <div className="relative bg-white border-2 border-black rounded-xl p-5 overflow-hidden shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] transition-all">
      <span className={`absolute -top-3 right-2 font-display font-extrabold text-6xl ${accent}/10 select-none leading-none`} aria-hidden="true">
        {number}
      </span>
      <h4 className="relative font-display font-bold text-lg text-black mb-2 leading-snug">{title}</h4>
      <p className="relative text-gray-500 text-sm leading-relaxed">{text}</p>
    </div>
  );
}

export default function Home({ auth }) {
  useFlash();

  return (
    <div>
      <Head>
        <script type="application/ld+json">{JSON.stringify(FAQ_JSON_LD)}</script>
      </Head>
      <Toaster position="top-center" />
      <LandingNav user={auth.user} />

      {/* HERO — two-column: copy left, live card stack right */}
      <section className="px-6 md:px-16 lg:px-24 pt-12 pb-10 md:pt-20 md:pb-20 grid md:grid-cols-2 gap-12 md:gap-20 items-center border-b-4 border-black">
        <div>
          <div className="inline-flex items-center gap-2 bg-white border-2 border-black rounded-full px-4 py-1.5 text-sm font-bold mb-6 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
            <span className="live-dot"></span>
            Now in beta · Accepting members
          </div>

          <h1 className="font-display font-extrabold text-5xl md:text-6xl lg:text-7xl leading-tight tracking-tight mb-5">
            A place where
            <br />
            programmers
            <br />
            <span className="bg-orange text-white px-2 rounded-md inline-block leading-tight">pair up</span>.
          </h1>

          <p className="text-gray-500 text-lg leading-relaxed max-w-sm mb-8">
            A community to grow, build and learn together.
          </p>

          <div className="flex flex-wrap gap-3">
            <a
              href="/users/sign_up"
              className="font-headline font-bold text-base px-7 py-3.5 rounded-md border-2 border-black bg-purple text-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
            >
              Start pairing free →
            </a>
            <a
              href="#how-it-works"
              className="font-headline font-bold text-base px-7 py-3.5 rounded-md border-2 border-black bg-yellow-50 text-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
            >
              How it works
            </a>
          </div>
        </div>

        {/* "Live now" list (visual mockup) */}
        <div className="relative hidden md:block">
          <div className="absolute -top-3 right-2 bg-green text-white text-xs font-bold px-3 py-1.5 rounded-md border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] z-10 flex items-center gap-1.5">
            <span className="live-dot"></span> Live now
          </div>
          <div className="flex flex-col gap-3 mt-4">
            {LIVE_NOW.map((dev) => (
              <div
                key={dev.name}
                className="bg-white border-2 border-black rounded-xl p-3.5 flex items-center gap-3 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[1px_1px_0px_0px_rgba(0,0,0,1)] transition-all"
              >
                <div className="w-10 h-10 rounded-lg bg-purple/10 border-2 border-black flex items-center justify-center text-lg flex-shrink-0">
                  {dev.emoji}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-display font-bold text-sm text-black">{dev.name}</p>
                  <div className="flex gap-1 mt-1 flex-wrap">
                    {dev.tags.map((tag) => (
                      <span key={tag} className="bg-purple text-white text-xs font-bold px-2 py-0.5 rounded border border-black">
                        {tag}
                      </span>
                    ))}
                    <span className="bg-orange text-white text-xs font-bold px-2 py-0.5 rounded border border-black">{dev.level}</span>
                  </div>
                </div>
                <button className="flex-shrink-0 bg-green text-white text-xs font-bold px-3 py-2 rounded-md border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[1px] hover:translate-y-[1px] hover:shadow-none transition-all">
                  Join
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* TECH MARQUEE — dark background, shows supported stacks */}
      <div className="relative flex w-full overflow-x-hidden border-b-4 border-black bg-black">
        <div className="animate-marquee whitespace-nowrap py-6 flex">
          {TECH_ICONS.map((icon) => (
            <span
              key={icon}
              className="flex justify-center items-center bg-orange border-2 border-orange/50 rounded-xl p-2 w-14 h-14 md:w-16 md:h-16 shadow-[3px_3px_0px_0px_rgba(255,255,255,0.1)] mx-3 text-3xl text-white"
            >
              <i className={`devicon-${icon}`}></i>
            </span>
          ))}
        </div>
        <div className="absolute top-0 animate-marquee2 whitespace-nowrap py-6 flex" aria-hidden="true">
          {TECH_ICONS.map((icon) => (
            <span
              key={icon}
              className="flex justify-center items-center bg-orange border-2 border-orange/50 rounded-xl p-2 w-14 h-14 md:w-16 md:h-16 mx-3 text-3xl text-white"
            >
              <i className={`devicon-${icon}`}></i>
            </span>
          ))}
        </div>
      </div>

      {/* STATS STRIP */}
      <div className="border-b-4 border-black px-6 md:px-24 py-8 grid grid-cols-2 md:grid-cols-4 gap-6 bg-yellow-50">
        <div className="text-center">
          <p className="font-display font-extrabold text-lg md:text-xl tracking-tight text-black">
            Free <span className="text-orange">during beta</span>
          </p>
        </div>
        <div className="text-center">
          <p className="font-display font-extrabold text-lg md:text-xl tracking-tight text-black">
            Match by <span className="text-orange">interest</span>
          </p>
        </div>
        <div className="text-center">
          <p className="font-display font-extrabold text-lg md:text-xl tracking-tight text-black">
            Live in <span className="text-orange">minutes</span>
          </p>
        </div>
        <div className="text-center">
          <p className="font-display font-extrabold text-lg md:text-xl tracking-tight text-black">
            Help <span className="text-orange">shape the roadmap</span>
          </p>
        </div>
      </div>

      {/* ABOUT — split layout: text left, illustration right */}
      <section className="px-6 md:px-16 lg:px-24 py-16 md:py-24 grid md:grid-cols-2 gap-12 md:gap-20 items-center border-b-4 border-black bg-white">
        <div>
          <span className="text-xs font-bold text-orange uppercase tracking-widest block mb-3">What is Pairin?</span>
          <h2 className="font-display font-extrabold text-4xl md:text-5xl tracking-tight leading-none mb-5">
            Find
            <br />
            programmers
            <br />
            like you
          </h2>
          <p className="text-gray-500 leading-relaxed text-base mb-6 max-w-md">
            <span className="font-bold text-black">Pairin.dev</span> is a community of developers connecting for pair
            programming and collaboration. Whether you need a coding buddy or a full project partner, you'll find the
            right match here.
          </p>
          <div className="flex flex-wrap gap-2">
            {ABOUT_CHIPS.map((chip) => (
              <span key={chip} className="border-2 border-black rounded-full px-4 py-1.5 text-sm font-bold bg-yellow-50 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
                {chip}
              </span>
            ))}
          </div>
        </div>

        <div className="relative flex justify-center">
          <div className="border-2 border-black rounded-2xl bg-yellow-50 p-8 shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] w-full max-w-sm">
            <img src={collaborateImage} alt="Programmers collaborating" className="w-full h-auto" />
          </div>
          <div className="absolute -top-4 -right-2 bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]">
            ✅ Matched
          </div>
          <div className="absolute -bottom-4 -left-2 bg-purple text-white border-2 border-black rounded-xl px-3 py-2 text-xs font-bold shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]">
            💬 React · TypeScript
          </div>
        </div>
      </section>

      {/* HOW IT WORKS — two-lane flow, converging into a shared final step */}
      <section id="how-it-works" className="px-6 md:px-16 lg:px-24 py-16 md:py-24 bg-yellow-50 border-b-4 border-black">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-4 mb-12">
          <div>
            <span className="text-xs font-bold text-purple uppercase tracking-widest block mb-3">How it works</span>
            <h2 className="font-display font-extrabold text-4xl md:text-5xl tracking-tight leading-none">
              Pair right now,
              <br />
              or plan ahead
            </h2>
          </div>
          <p className="text-gray-500 text-sm leading-relaxed max-w-xs md:text-right">
            Go live for an instant match, or post a request and schedule it for later — either way, you're pairing in
            minutes.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-10 gap-y-10 mb-8">
          {/* Lane — Live now */}
          <div>
            <div className="flex items-center gap-2 mb-5">
              <span className="w-3 h-3 rounded-full bg-green border-2 border-black shrink-0" aria-hidden="true"></span>
              <h3 className="font-display font-bold text-xs uppercase tracking-widest text-green">Live now</h3>
            </div>

            <div className="relative flex flex-col gap-5 pl-6">
              <div className="absolute left-0 top-2 bottom-2 w-0.5 bg-green/20" aria-hidden="true"></div>
              {LIVE_NOW_STEPS.map((step, i) => (
                <StepCard key={step.title} number={String(i + 1).padStart(2, "0")} title={step.title} text={step.text} accent="text-green" />
              ))}
            </div>
          </div>

          {/* Lane — Scheduled */}
          <div>
            <div className="flex items-center gap-2 mb-5">
              <span className="w-3 h-3 rounded-full bg-orange border-2 border-black shrink-0" aria-hidden="true"></span>
              <h3 className="font-display font-bold text-xs uppercase tracking-widest text-orange">Scheduled</h3>
            </div>

            <div className="relative flex flex-col gap-5 pl-6">
              <div className="absolute left-0 top-2 bottom-2 w-0.5 bg-orange/20" aria-hidden="true"></div>
              {SCHEDULED_STEPS.map((step, i) => (
                <StepCard key={step.title} number={String(i + 1).padStart(2, "0")} title={step.title} text={step.text} accent="text-orange" />
              ))}
            </div>
          </div>
        </div>

        {/* Convergence arrow — both lanes flow into the shared final step */}
        <div className="flex justify-center" aria-hidden="true">
          <svg width="20" height="28" viewBox="0 0 20 28" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M10 0V20M10 20L2 12M10 20L18 12"
              stroke="black"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>

        {/* Both flows converge */}
        <div className="relative bg-white border-2 border-black border-t-4 border-t-green rounded-xl p-6 md:p-8 overflow-hidden shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] transition-all text-center">
          <span className="inline-flex items-center gap-2 text-xs font-bold text-green uppercase tracking-widest mb-3">
            <span className="w-2.5 h-2.5 rounded-full bg-green border border-black" aria-hidden="true"></span> Everyone
          </span>
          <h3 className="font-display font-bold text-xl text-black mb-2 leading-snug">Start pairing</h3>
          <p className="text-gray-500 text-sm leading-relaxed max-w-md mx-auto">
            Confirm your coding partner — you're all set to pair.
          </p>
        </div>
      </section>

      {/* MORE — grid of smaller feature callouts */}
      <section className="px-6 md:px-16 lg:px-24 py-16 md:py-24 bg-white border-b-4 border-black">
        <div className="mb-10">
          <span className="text-xs font-bold text-orange uppercase tracking-widest block mb-3">And there's more</span>
          <h2 className="font-display font-extrabold text-4xl md:text-5xl tracking-tight leading-none">
            Built for the
            <br />
            whole session
          </h2>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {FEATURES.map((feature) => (
            <div
              key={feature.title}
              className="relative bg-yellow-50 border-2 border-black rounded-xl p-5 overflow-hidden shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] transition-all"
            >
              <div className={`w-10 h-10 rounded-lg ${feature.iconBg} border-2 border-black flex items-center justify-center text-lg mb-4`}>
                {feature.icon}
              </div>
              <h4 className="font-display font-bold text-base text-black mb-2 leading-snug">{feature.title}</h4>
              <p className="text-gray-500 text-sm leading-relaxed">{feature.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="px-6 md:px-16 lg:px-24 py-16 md:py-24 bg-yellow-50 border-b-4 border-black">
        <div className="mb-10">
          <span className="text-xs font-bold text-purple uppercase tracking-widest block mb-3">FAQ</span>
          <h2 className="font-display font-extrabold text-4xl md:text-5xl tracking-tight leading-none">
            Questions,
            <br />
            answered
          </h2>
        </div>

        <div className="flex flex-col gap-4 max-w-2xl">
          {FAQS.map((faq) => (
            <details key={faq.q} className="group bg-white border-2 border-black rounded-xl p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
              <summary className="font-display font-bold text-base text-black cursor-pointer list-none flex items-center justify-between gap-4">
                {faq.q}
                <span className="text-xl leading-none group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="text-gray-500 text-sm leading-relaxed mt-3">{faq.a}</p>
            </details>
          ))}
        </div>
      </section>

      {/* CTA — dark section: "Start pairin'" */}
      <section className="px-6 md:px-16 lg:px-24 py-16 md:py-24 bg-black border-b-4 border-black grid md:grid-cols-2 gap-12 md:gap-20 items-center">
        <div>
          <span className="text-xs font-bold text-gray-500 uppercase tracking-widest block mb-4">Ready?</span>
          <h2 className="font-display font-extrabold text-5xl md:text-6xl tracking-tight leading-none mb-5 text-white">
            Time to
            <br />
            <span className="text-orange">start pairin'</span>
          </h2>
          <p className="text-gray-400 leading-relaxed text-base mb-8 max-w-sm">
            Be one of the first developers building here. Go live and pair in minutes, or schedule for later.
          </p>
          <div className="flex flex-wrap gap-3">
            <a
              href="/users/sign_up"
              className="font-headline font-bold text-base px-7 py-3.5 rounded-md border-2 border-black bg-orange text-white shadow-[4px_4px_0px_0px_rgba(255,255,255,0.2)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
            >
              Pair right now →
            </a>
            <Link
              href="/pair_requests"
              className="font-headline font-bold text-base px-7 py-3.5 rounded-md border-2 border-white/20 text-white hover:bg-white/10 hover:border-white/40 transition-all"
            >
              Or schedule for later
            </Link>
          </div>
        </div>

        <div className="flex justify-center md:justify-end">
          <img src={startImage} alt="Programmer on the road to success" className="w-64 md:w-80 h-auto" />
        </div>
      </section>

      {/* COMMUNITY — purple section */}
      <section id="community" className="px-6 py-16 md:py-24 bg-purple border-b-4 border-black text-center">
        <span className="text-xs font-bold text-white/50 uppercase tracking-widest block mb-3">Join us</span>
        <h2 className="font-display font-extrabold text-4xl md:text-6xl tracking-tight leading-none text-white mb-4">
          Meet our members
        </h2>
        <p className="text-white/65 text-base leading-relaxed max-w-md mx-auto mb-8">
          Help us grow — our community is just getting started, and everyone who joins now gets a real say in where it
          goes.
        </p>

        <a
          href="/users/sign_up"
          className="inline-block font-headline font-bold text-base px-8 py-3.5 rounded-md border-2 border-black bg-white text-purple shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
        >
          Join our community →
        </a>

        <div className="mt-5">
          <span className="inline-flex items-center gap-2 bg-white/10 border border-white/20 rounded-full px-4 py-1.5 text-xs font-bold text-white/75">
            🌱 Shape the roadmap · Free to join
          </span>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="bg-black px-6 md:px-16 lg:px-24 pt-12 pb-6 border-b-4 border-black">
        <div className="grid md:grid-cols-3 gap-10 pb-10 border-b border-white/10 mb-6">
          <div>
            <div className="flex items-center gap-2 mb-3">
              <img src={logoImage} alt="Pairin logo" className="h-8 invert" />
              <span className="font-display font-bold text-white text-base tracking-tight">pairin</span>
            </div>
            <p className="text-white/40 text-sm leading-relaxed max-w-xs">
              Connect with the right coding partner, right now. Built for developers, by developers.
            </p>
          </div>

          <div>
            <h5 className="text-white/35 text-xs font-bold uppercase tracking-widest mb-4">Platform</h5>
            <ul className="flex flex-col gap-2.5">
              <li>
                <Link href="/pair_requests" className="text-white/60 text-sm hover:text-white transition-colors font-medium">
                  Start pairing
                </Link>
              </li>
              <li>
                <a href="/users/sign_up" className="text-white/60 text-sm hover:text-white transition-colors font-medium">
                  Sign up
                </a>
              </li>
              <li>
                <a href="/users/sign_in" className="text-white/60 text-sm hover:text-white transition-colors font-medium">
                  Log in
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="text-white/60 text-sm hover:text-white transition-colors font-medium">
                  How it works
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h5 className="text-white/35 text-xs font-bold uppercase tracking-widest mb-4">Company</h5>
            <ul className="flex flex-col gap-2.5">
              <li>
                <a href="#community" className="text-white/60 text-sm hover:text-white transition-colors font-medium">
                  Community
                </a>
              </li>
              <li>
                <span className="text-white/30 text-sm font-medium">Privacy policy</span>
              </li>
              <li>
                <span className="text-white/30 text-sm font-medium">Terms of service</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="flex items-center justify-between flex-wrap gap-3">
          <p className="text-white/25 text-xs">© {new Date().getFullYear()} Pairin. All rights reserved.</p>
          <p className="text-white/25 text-xs">made by Manufaktura Koda</p>
        </div>
      </footer>
    </div>
  );
}
