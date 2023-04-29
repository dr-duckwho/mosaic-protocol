import { Menu } from "@/components/groups/GroupContent";

function GroupContentTabItem({
  title,
  onChangeMenu,
  isSelected,
}: {
  title: string;
  onChangeMenu: () => void;
  isSelected?: boolean;
}) {
  return (
    <button
      onClick={() => onChangeMenu()}
      className={`${isSelected && "text-primary"} text-sm mr-6`}
    >
      {title}
      <div
        style={{ height: 1 }}
        className={`${isSelected && "bg-primary"} mt-3 relative z-10`}
      />
    </button>
  );
}

export default function GroupContentTab({
  selected,
  onChangeMenu,
}: {
  selected: Menu;
  onChangeMenu: (menu: Menu) => void;
}) {
  const titles = {
    details: "Details",
    "group-activity": "Group Activity",
    "phases-data": "Phases & Data",
  };

  return (
    <div className="relative">
      <div
        style={{
          color: "#918090",
        }}
        className="flex items-center"
      >
        {Object.entries(titles).map(([key, value]) => (
          <GroupContentTabItem
            key={key}
            title={value}
            onChangeMenu={() => onChangeMenu(key as Menu)}
            isSelected={key === selected}
          />
        ))}
      </div>
      <div
        style={{
          height: 1,
          backgroundColor: "#3E324B",
        }}
        className="mt-3 w-full absolute bottom-0 z-0"
      />
    </div>
  );
}
