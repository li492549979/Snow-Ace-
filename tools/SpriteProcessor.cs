using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class SpriteProcessor
{
    /// <summary>
    /// 处理精灵：自动检测背景色（品红/黑等单色），从四周洪泛填充抠图，
    /// 裁剪主体，等比缩放（contain）到目标画布并居中，输出透明 PNG。
    /// </summary>
    public static void Process(string input, string output, int targetW, int targetH, int tol)
    {
        using (Bitmap src = new Bitmap(input))
        {
            int w = src.Width, h = src.Height;
            using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
            {
                using (Graphics gr = Graphics.FromImage(bmp))
                {
                    gr.DrawImage(src, 0, 0, w, h);
                }

                Color bg = DetectBackground(bmp);
                int br = bg.R, bgr = bg.G, bb = bg.B;

                BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int stride = bd.Stride;
                byte[] data = new byte[stride * h];
                Marshal.Copy(bd.Scan0, data, 0, data.Length);

                bool[] visited = new bool[w * h];
                Queue<int> queue = new Queue<int>();

                Func<int, int, bool> isBg = delegate(int x, int y)
                {
                    int i = y * stride + x * 4;
                    int b = data[i], gg = data[i + 1], r = data[i + 2];
                    int dr = r - br, dg = gg - bgr, db = b - bb;
                    return (dr * dr + dg * dg + db * db) <= tol * tol;
                };

                Action<int, int> enq = delegate(int x, int y)
                {
                    if (x < 0 || y < 0 || x >= w || y >= h) return;
                    int idx = y * w + x;
                    if (visited[idx]) return;
                    if (isBg(x, y)) { visited[idx] = true; queue.Enqueue(idx); }
                };

                for (int x = 0; x < w; x++) { enq(x, 0); enq(x, h - 1); }
                for (int y = 0; y < h; y++) { enq(0, y); enq(w - 1, y); }

                while (queue.Count > 0)
                {
                    int idx = queue.Dequeue();
                    int x = idx % w, y = idx / w;
                    int i = y * stride + x * 4;
                    data[i + 3] = 0;
                    enq(x - 1, y);
                    enq(x + 1, y);
                    enq(x, y - 1);
                    enq(x, y + 1);
                }

                int minX = w, minY = h, maxX = -1, maxY = -1;
                for (int y = 0; y < h; y++)
                {
                    for (int x = 0; x < w; x++)
                    {
                        int i = y * stride + x * 4;
                        if (data[i + 3] > 0)
                        {
                            if (x < minX) minX = x;
                            if (x > maxX) maxX = x;
                            if (y < minY) minY = y;
                            if (y > maxY) maxY = y;
                        }
                    }
                }

                Marshal.Copy(data, 0, bd.Scan0, data.Length);
                bmp.UnlockBits(bd);

                if (maxX < 0)
                {
                    bmp.Save(output, ImageFormat.Png);
                    return;
                }

                int pad = 2;
                minX = Math.Max(0, minX - pad);
                minY = Math.Max(0, minY - pad);
                maxX = Math.Min(w - 1, maxX + pad);
                maxY = Math.Min(h - 1, maxY + pad);
                int cw = maxX - minX + 1;
                int ch = maxY - minY + 1;

                using (Bitmap crop = new Bitmap(cw, ch, PixelFormat.Format32bppArgb))
                {
                    using (Graphics g2 = Graphics.FromImage(crop))
                    {
                        g2.DrawImage(bmp, new Rectangle(0, 0, cw, ch), new Rectangle(minX, minY, cw, ch), GraphicsUnit.Pixel);
                    }

                    double s = Math.Min((double)targetW / cw, (double)targetH / ch);
                    int dw = Math.Max(1, (int)Math.Round(cw * s));
                    int dh = Math.Max(1, (int)Math.Round(ch * s));
                    int ox = (targetW - dw) / 2;
                    int oy = (targetH - dh) / 2;

                    using (Bitmap fin = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb))
                    {
                        using (Graphics g3 = Graphics.FromImage(fin))
                        {
                            g3.Clear(Color.Transparent);
                            g3.InterpolationMode = InterpolationMode.HighQualityBicubic;
                            g3.PixelOffsetMode = PixelOffsetMode.HighQuality;
                            g3.DrawImage(crop, new Rectangle(ox, oy, dw, dh));
                        }
                        fin.Save(output, ImageFormat.Png);
                    }
                }
            }
        }
    }

    /// <summary>
    /// 处理背景：不抠图，等比放大到铺满（cover）目标尺寸并居中裁剪，输出不透明 PNG。
    /// </summary>
    public static void ProcessBackground(string input, string output, int targetW, int targetH)
    {
        using (Bitmap src = new Bitmap(input))
        using (Bitmap fin = new Bitmap(targetW, targetH, PixelFormat.Format24bppRgb))
        {
            using (Graphics gr = Graphics.FromImage(fin))
            {
                gr.InterpolationMode = InterpolationMode.HighQualityBicubic;
                gr.PixelOffsetMode = PixelOffsetMode.HighQuality;
                double s = Math.Max((double)targetW / src.Width, (double)targetH / src.Height);
                int dw = Math.Max(1, (int)Math.Round(src.Width * s));
                int dh = Math.Max(1, (int)Math.Round(src.Height * s));
                int ox = (targetW - dw) / 2;
                int oy = (targetH - dh) / 2;
                gr.DrawImage(src, new Rectangle(ox, oy, dw, dh));
            }
            fin.Save(output, ImageFormat.Png);
        }
    }

    /// <summary>
    /// 处理需要透明通道的中/近景：抠掉背景色（品红等）成透明，等比铺满(cover)到目标尺寸，不裁剪主体。
    /// </summary>
    public static void ProcessBackgroundKeyed(string input, string output, int targetW, int targetH, int tol)
    {
        using (Bitmap src = new Bitmap(input))
        {
            int w = src.Width, h = src.Height;
            using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
            {
                using (Graphics gr = Graphics.FromImage(bmp))
                {
                    gr.DrawImage(src, 0, 0, w, h);
                }

                Color bg = DetectTopBackground(bmp);
                int br = bg.R, bgr = bg.G, bb = bg.B;

                BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int stride = bd.Stride;
                byte[] data = new byte[stride * h];
                Marshal.Copy(bd.Scan0, data, 0, data.Length);

                bool[] visited = new bool[w * h];
                Queue<int> queue = new Queue<int>();

                Func<int, int, bool> isBg = delegate(int x, int y)
                {
                    int i = y * stride + x * 4;
                    int b = data[i], gg = data[i + 1], r = data[i + 2];
                    int dr = r - br, dg = gg - bgr, db = b - bb;
                    return (dr * dr + dg * dg + db * db) <= tol * tol;
                };
                Action<int, int> enq = delegate(int x, int y)
                {
                    if (x < 0 || y < 0 || x >= w || y >= h) return;
                    int idx = y * w + x;
                    if (visited[idx]) return;
                    if (isBg(x, y)) { visited[idx] = true; queue.Enqueue(idx); }
                };
                for (int x = 0; x < w; x++) { enq(x, 0); enq(x, h - 1); }
                for (int y = 0; y < h; y++) { enq(0, y); enq(w - 1, y); }

                while (queue.Count > 0)
                {
                    int idx = queue.Dequeue();
                    int x = idx % w, y = idx / w;
                    int i = y * stride + x * 4;
                    data[i + 3] = 0;
                    enq(x - 1, y);
                    enq(x + 1, y);
                    enq(x, y - 1);
                    enq(x, y + 1);
                }
                Marshal.Copy(data, 0, bd.Scan0, data.Length);
                bmp.UnlockBits(bd);

                using (Bitmap fin = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb))
                {
                    using (Graphics g2 = Graphics.FromImage(fin))
                    {
                        g2.Clear(Color.Transparent);
                        g2.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g2.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        double s = Math.Max((double)targetW / w, (double)targetH / h);
                        int dw = Math.Max(1, (int)Math.Round(w * s));
                        int dh = Math.Max(1, (int)Math.Round(h * s));
                        int ox = (targetW - dw) / 2;
                        int oy = (targetH - dh) / 2;
                        g2.DrawImage(bmp, new Rectangle(ox, oy, dw, dh));
                    }
                    fin.Save(output, ImageFormat.Png);
                }
            }
        }
    }

    /// <summary>
    /// 从顶部边缘采样背景色（用于中/近景：天空/品红在上方，剪影在下方）。
    /// </summary>
    private static Color DetectTopBackground(Bitmap bmp)
    {
        int w = bmp.Width, h = bmp.Height;
        long sr = 0, sg = 0, sb = 0;
        int n = 0;
        for (int x = 0; x < w; x += 8)
        {
            Color c = bmp.GetPixel(x, 0); sr += c.R; sg += c.G; sb += c.B; n++;
        }
        if (n == 0) return Color.Magenta;
        return Color.FromArgb((int)(sr / n), (int)(sg / n), (int)(sb / n));
    }

    private static Color DetectBackground(Bitmap bmp)
    {
        int w = bmp.Width, h = bmp.Height;
        long sr = 0, sg = 0, sb = 0;
        int n = 0;
        for (int x = 0; x < w; x += 16)
        {
            Color c = bmp.GetPixel(x, 0); sr += c.R; sg += c.G; sb += c.B; n++;
            c = bmp.GetPixel(x, h - 1); sr += c.R; sg += c.G; sb += c.B; n++;
        }
        for (int y = 0; y < h; y += 16)
        {
            Color c = bmp.GetPixel(0, y); sr += c.R; sg += c.G; sb += c.B; n++;
            c = bmp.GetPixel(w - 1, y); sr += c.R; sg += c.G; sb += c.B; n++;
        }
        if (n == 0) return Color.Black;
        return Color.FromArgb((int)(sr / n), (int)(sg / n), (int)(sb / n));
    }
}
