export const CATEGORY_COLORS: Record<string, { from: string; to: string; text: string }> = {
  business: { from: "#F59E0B", to: "#D97706", text: "#000" },
  tech: { from: "#3B82F6", to: "#2563EB", text: "#FFF" },
  culture: { from: "#A855F7", to: "#7C3AED", text: "#FFF" },
  politics: { from: "#EF4444", to: "#DC2626", text: "#FFF" },
  sports: { from: "#10B981", to: "#059669", text: "#FFF" },
  world: { from: "#F97316", to: "#EA580C", text: "#FFF" },
  science: { from: "#06B6D4", to: "#0891B2", text: "#FFF" },
  default: { from: "#6B7280", to: "#4B5563", text: "#FFF" },
};

export function getCategoryColor(category: string) {
  return CATEGORY_COLORS[category.toLowerCase()] ?? CATEGORY_COLORS.default;
}

export function timeAgo(date: string | Date): string {
  const now = new Date();
  const then = new Date(date);
  const diff = Math.floor((now.getTime() - then.getTime()) / 1000);

  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
  return then.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}
