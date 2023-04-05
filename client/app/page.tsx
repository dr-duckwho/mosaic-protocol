import { Inter } from "next/font/google";
import ClientOnly from "@/components/ClientOnly";
import CuratorRole from "@/components/CuratorRole";

const inter = Inter({ subsets: ["latin"] });

export default function Home() {
  return (
    <>
      <h1 className="text-3xl font-bold underline">Test Page</h1>
      <ClientOnly>
        <CuratorRole />
      </ClientOnly>
    </>
  );
}
