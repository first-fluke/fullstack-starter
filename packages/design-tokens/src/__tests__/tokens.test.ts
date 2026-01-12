import { describe, expect, it } from "vitest";
import type { OklchColor } from "./src/tokens.js";
import {
  gammaEncode,
  linearSrgbToXyz,
  oklabToLinearSrgb,
  oklchToCss,
  oklchToOklab,
  oklchToP3,
  p3ToFlutterColor,
  p3ToHex,
  xyzToLinearP3,
} from "./tooling/oklch-to-p3.js";

describe("OKLCH to P3 conversion", () => {
  describe("oklchToOklab", () => {
    it("should convert pure white correctly", () => {
      const white: OklchColor = { l: 1, c: 0, h: 0 };
      const result = oklchToOklab(white);

      expect(result.L).toBe(1);
      expect(result.a).toBeCloseTo(0, 5);
      expect(result.b).toBeCloseTo(0, 5);
    });

    it("should convert pure black correctly", () => {
      const black: OklchColor = { l: 0, c: 0, h: 0 };
      const result = oklchToOklab(black);

      expect(result.L).toBe(0);
      expect(result.a).toBeCloseTo(0, 5);
      expect(result.b).toBeCloseTo(0, 5);
    });

    it("should handle chromatic colors", () => {
      const color: OklchColor = { l: 0.7, c: 0.15, h: 90 };
      const result = oklchToOklab(color);

      expect(result.L).toBe(0.7);
      expect(result.a).toBeCloseTo(0, 2);
      expect(result.b).toBeCloseTo(0.15, 2);
    });
  });

  describe("oklabToLinearSrgb", () => {
    it("should convert neutral gray", () => {
      const gray = { L: 0.5, a: 0, b: 0 };
      const [r, g, b] = oklabToLinearSrgb(gray);

      expect(r).toBeCloseTo(g, 3);
      expect(g).toBeCloseTo(b, 3);
    });
  });

  describe("linearSrgbToXyz", () => {
    it("should preserve neutral colors on diagonal", () => {
      const neutral: [number, number, number] = [0.5, 0.5, 0.5];
      const [, y] = linearSrgbToXyz(neutral);

      expect(y).toBeCloseTo(0.5, 2);
    });
  });

  describe("xyzToLinearP3", () => {
    it("should handle D65 white point", () => {
      const d65White: [number, number, number] = [0.9505, 1.0, 1.089];
      const [r, g, b] = xyzToLinearP3(d65White);

      expect(r).toBeCloseTo(1, 1);
      expect(g).toBeCloseTo(1, 1);
      expect(b).toBeCloseTo(1, 1);
    });
  });

  describe("gammaEncode", () => {
    it("should handle linear values below threshold", () => {
      const result = gammaEncode(0.001);
      expect(result).toBeCloseTo(0.01292, 4);
    });

    it("should handle linear values above threshold", () => {
      const result = gammaEncode(0.5);
      expect(result).toBeGreaterThan(0.5);
      expect(result).toBeLessThan(1);
    });

    it("should clamp at 0 and 1", () => {
      expect(gammaEncode(0)).toBe(0);
      expect(gammaEncode(1)).toBeCloseTo(1, 5);
    });
  });

  describe("oklchToP3", () => {
    it("should convert pure white", () => {
      const white: OklchColor = { l: 1, c: 0, h: 0 };
      const result = oklchToP3(white);

      expect(result.r).toBeCloseTo(1, 2);
      expect(result.g).toBeCloseTo(1, 2);
      expect(result.b).toBeCloseTo(1, 2);
      expect(result.a).toBe(1);
    });

    it("should convert pure black", () => {
      const black: OklchColor = { l: 0, c: 0, h: 0 };
      const result = oklchToP3(black);

      expect(result.r).toBeCloseTo(0, 2);
      expect(result.g).toBeCloseTo(0, 2);
      expect(result.b).toBeCloseTo(0, 2);
      expect(result.a).toBe(1);
    });

    it("should preserve alpha channel", () => {
      const semiTransparent: OklchColor = { l: 0.5, c: 0, h: 0, a: 0.5 };
      const result = oklchToP3(semiTransparent);

      expect(result.a).toBe(0.5);
    });

    it("should clamp out-of-gamut colors", () => {
      const vividColor: OklchColor = { l: 0.7, c: 0.4, h: 150 };
      const result = oklchToP3(vividColor);

      expect(result.r).toBeGreaterThanOrEqual(0);
      expect(result.r).toBeLessThanOrEqual(1);
      expect(result.g).toBeGreaterThanOrEqual(0);
      expect(result.g).toBeLessThanOrEqual(1);
      expect(result.b).toBeGreaterThanOrEqual(0);
      expect(result.b).toBeLessThanOrEqual(1);
    });
  });
});

describe("CSS generation", () => {
  describe("oklchToCss", () => {
    it("should generate correct OKLCH string without alpha", () => {
      const color: OklchColor = { l: 0.85, c: 0.2, h: 130 };
      const result = oklchToCss(color);

      expect(result).toBe("oklch(0.85 0.2 130)");
    });

    it("should include alpha when less than 1", () => {
      const color: OklchColor = { l: 1, c: 0, h: 0, a: 0.5 };
      const result = oklchToCss(color);

      expect(result).toBe("oklch(1 0 0 / 0.5)");
    });

    it("should omit alpha when 1", () => {
      const color: OklchColor = { l: 0.5, c: 0.1, h: 45, a: 1 };
      const result = oklchToCss(color);

      expect(result).toBe("oklch(0.5 0.1 45)");
    });
  });
});

describe("Flutter generation", () => {
  describe("p3ToFlutterColor", () => {
    it("should generate correct Color.from format", () => {
      const p3 = { r: 0.5, g: 0.75, b: 0.25, a: 1 };
      const result = p3ToFlutterColor(p3);

      expect(result).toContain("Color.from");
      expect(result).toContain("alpha: 1.000");
      expect(result).toContain("red: 0.5000");
      expect(result).toContain("green: 0.7500");
      expect(result).toContain("blue: 0.2500");
      expect(result).toContain("colorSpace: ColorSpace.displayP3");
    });

    it("should handle semi-transparent colors", () => {
      const p3 = { r: 1, g: 0, b: 0, a: 0.5 };
      const result = p3ToFlutterColor(p3);

      expect(result).toContain("alpha: 0.500");
    });
  });

  describe("p3ToHex", () => {
    it("should convert to hex without alpha", () => {
      const p3 = { r: 1, g: 0.5, b: 0, a: 1 };
      const result = p3ToHex(p3);

      expect(result).toBe("#ff8000");
    });

    it("should include alpha in hex when less than 1", () => {
      const p3 = { r: 0, g: 0, b: 0, a: 0.5 };
      const result = p3ToHex(p3);

      expect(result).toBe("#00000080");
    });

    it("should clamp values", () => {
      const p3 = { r: 1.5, g: -0.5, b: 0.5, a: 1 };
      const result = p3ToHex(p3);

      expect(result).toBe("#ff0080");
    });
  });
});

describe("Alpha channel handling", () => {
  it("should preserve alpha through full conversion pipeline", () => {
    const semiTransparent: OklchColor = { l: 0.5, c: 0.1, h: 200, a: 0.3 };

    const css = oklchToCss(semiTransparent);
    expect(css).toContain("/ 0.3");

    const p3 = oklchToP3(semiTransparent);
    expect(p3.a).toBe(0.3);

    const flutter = p3ToFlutterColor(p3);
    expect(flutter).toContain("alpha: 0.300");
  });

  it("should default alpha to 1 when not specified", () => {
    const opaque: OklchColor = { l: 0.5, c: 0.1, h: 200 };

    const p3 = oklchToP3(opaque);
    expect(p3.a).toBe(1);
  });
});
