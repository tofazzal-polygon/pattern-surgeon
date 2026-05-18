import { price, label } from "./pricing";

test("regular price", () => expect(price("regular", 100)).toBe(100));
test("vip price", () => expect(price("vip", 100)).toBe(80));
test("regular label", () => expect(label("regular")).toBe("Standard"));
test("vip label", () => expect(label("vip")).toBe("VIP"));
