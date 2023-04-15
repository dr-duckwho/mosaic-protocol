interface TitleProps {
  title: string;
  badge?: string;
}

export function Title({ title, badge }: TitleProps) {
  return (
    <>
      {badge && (
        <div className="flex justify-center mt-8 mb-4">
          <div className="text-center inline-block px-2.5 py-1.5 rounded-xl bg-badge text-badgeText font-medium">
            {badge}
          </div>
        </div>
      )}
      <h1
        className={`text-title font-bold text-4xl text-center px-6 mb-24 ${
          !badge && "mt-20"
        }`}
      >
        {title}
      </h1>
    </>
  );
}
