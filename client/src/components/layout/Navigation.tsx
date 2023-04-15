"use client";

import Image from "next/image";
import ConnectButton from "@/components/contracts/wrapped/ConnectButton";
import { useState } from "react";
import Link from "next/link";

export function Navigation() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  return (
    <>
      <nav className="flex fixed px-5 w-full h-14 bg-secondary justify-between z-50">
        <Link className="flex items-center" href="/">
          <Image src="/logo.svg" width={21.95} height={20.41} alt="logo" />
        </Link>
        <div className="flex items-center">
          <ConnectButton label="Connect" />
          <button onClick={() => setIsMenuOpen(!isMenuOpen)}>
            <Image
              className="ml-4"
              src="/hamburger.svg"
              width={24}
              height={16}
              alt="menu"
            />
          </button>
        </div>
      </nav>
      <div className="h-14"></div>
      <section
        className={`fixed top-14 left-0 w-full h-full bg-secondary flex-col z-50 ${
          isMenuOpen ? "block" : "hidden"
        }`}
      >
        <div>
          <ul className="px-5 pt-6 pb-20 text-xl font-medium">
            <li className="mb-4">
              <Link
                className="block w-full"
                href="/"
                onClick={() => setIsMenuOpen(false)}
              >
                Home
              </Link>
            </li>
            <li className="mb-4">
              <Link
                className="block w-full"
                href="/about"
                onClick={() => setIsMenuOpen(false)}
              >
                About
              </Link>
            </li>
            <li className="mb-4">
              <Link
                className="block w-full"
                href="/faq"
                onClick={() => setIsMenuOpen(false)}
              >
                FAQ
              </Link>
            </li>
            <li>
              <Link
                className="block w-full"
                href="/account"
                onClick={() => setIsMenuOpen(false)}
              >
                Account
              </Link>
            </li>
          </ul>
          <div className="bg-secondary opacity-10" />
        </div>
      </section>
    </>
  );
}
