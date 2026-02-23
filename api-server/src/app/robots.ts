import { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/api/", "/login", "/signup"],
      },
      {
        userAgent: "Googlebot",
        allow: ["/", "/api/og"],
      },
      {
        userAgent: "Googlebot-News",
        allow: "/",
      },
    ],
    sitemap: "https://thedailypoop.lol/sitemap.xml",
  };
}
