"use client";

import GroupContentTab from "@/components/groups/GroupContentTab";
import GroupContentDetails from "@/components/groups/GroupContentDetails";
import React, { useState } from "react";
import GroupContentActivity from "@/components/groups/GroupContentActivity";
import GroupContentPhaseData from "@/components/groups/GroupContentPhaseData";

export type Menu = "details" | "group-activity" | "phases-data";

export default function GroupContent() {
  const [menu, setMenu] = useState<Menu>("phases-data");
  const onChangeMenu = (menu: Menu) => setMenu(menu);
  return (
    <section className="pt-7 px-5">
      <GroupContentTab selected={menu} onChangeMenu={onChangeMenu} />
      {menu === "details" && <GroupContentDetails />}
      {menu === "group-activity" && <GroupContentActivity />}
      {menu === "phases-data" && <GroupContentPhaseData />}
    </section>
  );
}
