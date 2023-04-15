import Image from "next/image";
import Link from "next/link";

interface FeatureButtonProps {
  title: string;
  href: string;
  light?: boolean;
  icon?: string;
  className?: string;
}

export function Button({
  title,
  href,
  light = false,
  icon,
  className,
}: FeatureButtonProps) {
  return (
    <Link href={href}>
      <div className={className}>
        <button
          className="box-content py-5 w-full font-bold flex items-center justify-center"
          style={
            light
              ? {
                  color: "#000000",
                  background: "#B97FFA",
                }
              : {
                  color: "#B97FFA",
                  background: "#331235",
                }
          }
        >
          {icon && (
            <Image
              src={`/${icon}.svg`}
              alt={`${icon}`}
              width={19.2}
              height={17.61}
            />
          )}
          <div className={`${icon ? "pl-2.5" : ""}`}>{title}</div>
        </button>
      </div>
    </Link>
  );
}
