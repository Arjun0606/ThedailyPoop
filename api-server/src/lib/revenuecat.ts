"use client";

import { Purchases } from "@revenuecat/purchases-js";

let instance: Purchases | null = null;

export function initRevenueCat(userId: string): Purchases {
  instance = Purchases.configure(
    process.env.NEXT_PUBLIC_REVENUECAT_WEB_KEY!,
    userId
  );
  return instance;
}

export function getRevenueCat(): Purchases | null {
  return instance;
}

export async function purchasePackage(
  rc: Purchases,
  packageIdentifier: string
) {
  const offerings = await rc.getOfferings();
  const current = offerings.current;
  if (!current) throw new Error("No offerings available");

  const pkg = current.availablePackages.find(
    (p) => p.rcBillingProduct?.identifier === packageIdentifier
  );
  if (!pkg) throw new Error(`Package ${packageIdentifier} not found`);

  return rc.purchase({ rcPackage: pkg });
}

export async function checkEntitlement(rc: Purchases): Promise<boolean> {
  const info = await rc.getCustomerInfo();
  return info.entitlements.active["premium"] !== undefined;
}
