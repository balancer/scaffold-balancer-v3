import { useQuery } from "wagmi";

type HookData = {
  id: number;
  title: string;
  source: string;
  description: string;
  github: string;
  additional_link: string;
  created_by: string;
  audited: "Yes" | "No";
  category: string[];
};
/**
 * Fetch hooks list data from balancer repo
 */
export const useHooks = () => {
  return useQuery<HookData[]>(["hooks"], async () => {
    const response = await fetch("https://raw.githubusercontent.com/burns2854/balancer-hooks/main/hook-data.json");

    if (!response.ok) {
      throw new Error(`Request failed with status: ${response.status}`);
    }
    return response.json();
  });
};
