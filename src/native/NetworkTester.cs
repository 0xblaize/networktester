using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace NetworkTesterNative
{
    public class MainForm : Form
    {
        private const string DownloadUrl = "https://speed.cloudflare.com/__down";
        private const string UploadUrl = "https://speed.cloudflare.com/__up";

        private readonly GaugeControl gauge;
        private readonly Label speedValue;
        private readonly Label speedUnit;
        private readonly Label speedLabel;
        private readonly Label downloadResult;
        private readonly Label uploadResult;
        private readonly Label pingResult;
        private readonly ProgressBar progressBar;
        private readonly Label progressText;
        private readonly Button startButton;
        private readonly Button resetButton;
        private readonly TextBox websiteInput;
        private readonly Button websiteButton;
        private readonly Label websiteResult;

        private volatile bool isTesting;

        public MainForm()
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            Text = "Network Tester";
            StartPosition = FormStartPosition.CenterScreen;
            MinimumSize = new Size(760, 820);
            Size = new Size(820, 900);
            BackColor = Color.FromArgb(16, 24, 32);

            var root = new TableLayoutPanel();
            root.Dock = DockStyle.Fill;
            root.ColumnCount = 1;
            root.RowCount = 2;
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, 92));
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            Controls.Add(root);

            var header = new Panel();
            header.Dock = DockStyle.Fill;
            header.BackColor = Color.FromArgb(24, 38, 50);
            root.Controls.Add(header, 0, 0);

            var title = new Label();
            title.Text = "Network Tester";
            title.ForeColor = Color.White;
            title.Font = new Font("Segoe UI", 22, FontStyle.Bold);
            title.TextAlign = ContentAlignment.MiddleCenter;
            title.Dock = DockStyle.Top;
            title.Height = 52;
            header.Controls.Add(title);

            var subtitle = new Label();
            subtitle.Text = "Real internet speed testing";
            subtitle.ForeColor = Color.FromArgb(215, 225, 235);
            subtitle.Font = new Font("Segoe UI", 10, FontStyle.Regular);
            subtitle.TextAlign = ContentAlignment.MiddleCenter;
            subtitle.Dock = DockStyle.Fill;
            header.Controls.Add(subtitle);

            var body = new Panel();
            body.Dock = DockStyle.Fill;
            body.BackColor = Color.White;
            body.Padding = new Padding(28);
            root.Controls.Add(body, 0, 1);

            var layout = new TableLayoutPanel();
            layout.Dock = DockStyle.Fill;
            layout.ColumnCount = 1;
            layout.RowCount = 7;
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 300));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 110));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 58));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 150));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 26));
            body.Controls.Add(layout);

            var speedPanel = new Panel();
            speedPanel.Dock = DockStyle.Fill;
            speedPanel.BackColor = Color.FromArgb(245, 248, 251);
            speedPanel.Padding = new Padding(18);
            layout.Controls.Add(speedPanel, 0, 0);

            gauge = new GaugeControl();
            gauge.Dock = DockStyle.Top;
            gauge.Height = 170;
            speedPanel.Controls.Add(gauge);

            speedValue = new Label();
            speedValue.Text = "0";
            speedValue.ForeColor = Color.FromArgb(24, 38, 50);
            speedValue.Font = new Font("Segoe UI", 42, FontStyle.Bold);
            speedValue.TextAlign = ContentAlignment.MiddleCenter;
            speedValue.Dock = DockStyle.Top;
            speedValue.Height = 76;
            speedPanel.Controls.Add(speedValue);

            speedUnit = new Label();
            speedUnit.Text = "Mbps";
            speedUnit.ForeColor = Color.FromArgb(95, 111, 126);
            speedUnit.Font = new Font("Segoe UI", 16, FontStyle.Regular);
            speedUnit.TextAlign = ContentAlignment.MiddleCenter;
            speedUnit.Dock = DockStyle.Top;
            speedUnit.Height = 32;
            speedPanel.Controls.Add(speedUnit);

            speedLabel = new Label();
            speedLabel.Text = "Click Start Test to begin";
            speedLabel.ForeColor = Color.FromArgb(105, 120, 135);
            speedLabel.Font = new Font("Segoe UI", 10, FontStyle.Regular);
            speedLabel.TextAlign = ContentAlignment.MiddleCenter;
            speedLabel.Dock = DockStyle.Fill;
            speedPanel.Controls.Add(speedLabel);

            var resultGrid = new TableLayoutPanel();
            resultGrid.Dock = DockStyle.Fill;
            resultGrid.ColumnCount = 3;
            resultGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33f));
            resultGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33f));
            resultGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33f));
            resultGrid.Padding = new Padding(0, 16, 0, 10);
            layout.Controls.Add(resultGrid, 0, 1);

            downloadResult = AddMetricCard(resultGrid, 0, "Download", "-- Mbps");
            uploadResult = AddMetricCard(resultGrid, 1, "Upload", "-- Mbps");
            pingResult = AddMetricCard(resultGrid, 2, "Ping", "-- ms");

            var progressPanel = new Panel();
            progressPanel.Dock = DockStyle.Fill;
            layout.Controls.Add(progressPanel, 0, 2);

            progressBar = new ProgressBar();
            progressBar.Dock = DockStyle.Top;
            progressBar.Height = 14;
            progressBar.Maximum = 100;
            progressPanel.Controls.Add(progressBar);

            progressText = new Label();
            progressText.Text = "Ready to test real internet speed";
            progressText.ForeColor = Color.FromArgb(102, 113, 125);
            progressText.TextAlign = ContentAlignment.MiddleCenter;
            progressText.Dock = DockStyle.Fill;
            progressPanel.Controls.Add(progressText);

            var buttonGrid = new TableLayoutPanel();
            buttonGrid.Dock = DockStyle.Fill;
            buttonGrid.ColumnCount = 2;
            buttonGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
            buttonGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
            layout.Controls.Add(buttonGrid, 0, 3);

            startButton = MakeButton("START TEST", Color.FromArgb(20, 110, 245), Color.White);
            startButton.Click += async delegate { await StartSpeedTest(); };
            buttonGrid.Controls.Add(startButton, 0, 0);

            resetButton = MakeButton("RESET", Color.FromArgb(237, 243, 248), Color.FromArgb(20, 110, 245));
            resetButton.Click += delegate { ResetTest(); };
            buttonGrid.Controls.Add(resetButton, 1, 0);

            var websitePanel = new Panel();
            websitePanel.Dock = DockStyle.Fill;
            websitePanel.BackColor = Color.FromArgb(248, 249, 250);
            websitePanel.Padding = new Padding(16);
            layout.Controls.Add(websitePanel, 0, 4);

            var websiteTitle = new Label();
            websiteTitle.Text = "Website Test";
            websiteTitle.Font = new Font("Segoe UI", 12, FontStyle.Bold);
            websiteTitle.ForeColor = Color.FromArgb(24, 38, 50);
            websiteTitle.Dock = DockStyle.Top;
            websiteTitle.Height = 28;
            websitePanel.Controls.Add(websiteTitle);

            var websiteControls = new TableLayoutPanel();
            websiteControls.Dock = DockStyle.Top;
            websiteControls.Height = 42;
            websiteControls.ColumnCount = 2;
            websiteControls.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            websiteControls.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 150));
            websitePanel.Controls.Add(websiteControls);

            websiteInput = new TextBox();
            websiteInput.Text = "https://example.com";
            websiteInput.Font = new Font("Segoe UI", 10, FontStyle.Regular);
            websiteInput.Dock = DockStyle.Fill;
            websiteControls.Controls.Add(websiteInput, 0, 0);

            websiteButton = MakeButton("TEST WEBSITE", Color.FromArgb(20, 110, 245), Color.White);
            websiteButton.Click += async delegate { await TestWebsite(); };
            websiteControls.Controls.Add(websiteButton, 1, 0);

            websiteResult = new Label();
            websiteResult.Text = "Enter a website URL to test its response from this PC.";
            websiteResult.ForeColor = Color.FromArgb(102, 113, 125);
            websiteResult.Font = new Font("Segoe UI", 9, FontStyle.Regular);
            websiteResult.Dock = DockStyle.Fill;
            websiteResult.Padding = new Padding(0, 10, 0, 0);
            websitePanel.Controls.Add(websiteResult);

            var info = new Label();
            info.Text = "Download and upload tests send real data to Cloudflare speed test servers. Results depend on your ISP, Wi-Fi, firewall, and current network load.";
            info.ForeColor = Color.FromArgb(102, 113, 125);
            info.Dock = DockStyle.Fill;
            info.Padding = new Padding(0, 14, 0, 0);
            layout.Controls.Add(info, 0, 5);

            var footer = new Label();
            footer.Text = "Network Tester";
            footer.ForeColor = Color.FromArgb(122, 135, 148);
            footer.TextAlign = ContentAlignment.MiddleCenter;
            footer.Dock = DockStyle.Fill;
            layout.Controls.Add(footer, 0, 6);
        }

        private static Label AddMetricCard(TableLayoutPanel grid, int column, string title, string value)
        {
            var panel = new Panel();
            panel.BackColor = Color.FromArgb(248, 249, 250);
            panel.Margin = new Padding(6);
            panel.Padding = new Padding(10);
            panel.Dock = DockStyle.Fill;
            grid.Controls.Add(panel, column, 0);

            var titleLabel = new Label();
            titleLabel.Text = title.ToUpperInvariant();
            titleLabel.ForeColor = Color.FromArgb(102, 113, 125);
            titleLabel.Font = new Font("Segoe UI", 8, FontStyle.Bold);
            titleLabel.TextAlign = ContentAlignment.MiddleCenter;
            titleLabel.Dock = DockStyle.Top;
            titleLabel.Height = 28;
            panel.Controls.Add(titleLabel);

            var valueLabel = new Label();
            valueLabel.Text = value;
            valueLabel.ForeColor = Color.FromArgb(15, 138, 95);
            valueLabel.Font = new Font("Segoe UI", 16, FontStyle.Bold);
            valueLabel.TextAlign = ContentAlignment.MiddleCenter;
            valueLabel.Dock = DockStyle.Fill;
            panel.Controls.Add(valueLabel);

            return valueLabel;
        }

        private static Button MakeButton(string text, Color background, Color foreground)
        {
            var button = new Button();
            button.Text = text;
            button.BackColor = background;
            button.ForeColor = foreground;
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderSize = 0;
            button.Font = new Font("Segoe UI", 10, FontStyle.Bold);
            button.Dock = DockStyle.Fill;
            button.Margin = new Padding(6);
            return button;
        }

        private async Task StartSpeedTest()
        {
            if (isTesting) return;

            isTesting = true;
            startButton.Enabled = false;
            resetButton.Enabled = false;
            ResetTest();

            try
            {
                SetProgress(2, "Connecting to external speed test server...");
                int ping = await Task.Run(new Func<int>(MeasurePing));
                pingResult.Text = ping + " ms";
                UpdateMain(ping, "External Ping", "ms", 0);

                SetProgress(20, "Testing real download speed...");
                double download = await Task.Run(new Func<double>(MeasureDownload));
                downloadResult.Text = download.ToString("0.00") + " Mbps";
                UpdateMain(download, "Download Speed", "Mbps", download);

                SetProgress(62, "Testing real upload speed...");
                double upload = await Task.Run(new Func<double>(MeasureUpload));
                uploadResult.Text = upload.ToString("0.00") + " Mbps";
                UpdateMain(upload, "Upload Speed", "Mbps", upload);

                SetProgress(100, "Real internet speed test complete");
            }
            catch (Exception ex)
            {
                SetProgress(0, "Error: " + ex.Message);
                UpdateMain(0, "Error", "Mbps", 0);
            }
            finally
            {
                startButton.Enabled = true;
                resetButton.Enabled = true;
                isTesting = false;
            }
        }

        private int MeasurePing()
        {
            var samples = new List<double>();
            for (int i = 0; i < 6; i++)
            {
                var watch = Stopwatch.StartNew();
                var request = (HttpWebRequest)WebRequest.Create(DownloadUrl + "?bytes=0&r=" + Guid.NewGuid().ToString("N"));
                request.Method = "GET";
                request.CachePolicy = new System.Net.Cache.RequestCachePolicy(System.Net.Cache.RequestCacheLevel.NoCacheNoStore);
                request.Timeout = 12000;
                using (var response = (HttpWebResponse)request.GetResponse())
                using (var stream = response.GetResponseStream())
                {
                    if (stream != null) stream.ReadByte();
                }
                watch.Stop();
                samples.Add(watch.Elapsed.TotalMilliseconds);
                Thread.Sleep(120);
            }

            samples.Sort();
            samples.RemoveAt(0);
            samples.RemoveAt(samples.Count - 1);
            return (int)Math.Round(Average(samples));
        }

        private double MeasureDownload()
        {
            int[] sizes = {
                1024 * 1024,
                5 * 1024 * 1024,
                10 * 1024 * 1024,
                25 * 1024 * 1024
            };

            var speeds = new List<double>();
            var totalWatch = Stopwatch.StartNew();
            long totalBytes = 0;
            int index = 0;

            while (totalWatch.ElapsedMilliseconds < 12000)
            {
                int size = sizes[Math.Min(index, sizes.Length - 1)];
                var requestWatch = Stopwatch.StartNew();
                long requestBytes = DownloadBytes(size, delegate(long bytes)
                {
                    totalBytes += bytes;
                    double current = BytesToMbps(totalBytes, totalWatch.Elapsed.TotalSeconds);
                    BeginInvoke(new Action(delegate
                    {
                        UpdateMain(current, "Download Speed", "Mbps", current);
                        SetProgress(20 + Math.Min(40, (int)(totalWatch.ElapsedMilliseconds / 12000.0 * 40)), "Testing real download speed...");
                    }));
                });
                requestWatch.Stop();

                if (requestWatch.Elapsed.TotalSeconds > 0.15)
                {
                    speeds.Add(BytesToMbps(requestBytes, requestWatch.Elapsed.TotalSeconds));
                }
                index++;
            }

            if (totalBytes == 0) throw new Exception("No download data was received");
            return Percentile(speeds, 0.8);
        }

        private long DownloadBytes(int size, Action<long> onBytes)
        {
            var request = (HttpWebRequest)WebRequest.Create(DownloadUrl + "?bytes=" + size + "&r=" + Guid.NewGuid().ToString("N"));
            request.Method = "GET";
            request.Timeout = 20000;
            request.CachePolicy = new System.Net.Cache.RequestCachePolicy(System.Net.Cache.RequestCacheLevel.NoCacheNoStore);

            long total = 0;
            var buffer = new byte[64 * 1024];
            using (var response = (HttpWebResponse)request.GetResponse())
            using (var stream = response.GetResponseStream())
            {
                if (stream == null) return 0;
                int read;
                while ((read = stream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    total += read;
                    onBytes(read);
                }
            }
            return total;
        }

        private double MeasureUpload()
        {
            int[] sizes = {
                512 * 1024,
                1024 * 1024,
                5 * 1024 * 1024,
                10 * 1024 * 1024
            };

            var speeds = new List<double>();
            var totalWatch = Stopwatch.StartNew();
            long totalBytes = 0;
            int index = 0;

            while (totalWatch.ElapsedMilliseconds < 10000)
            {
                int size = sizes[Math.Min(index, sizes.Length - 1)];
                var data = new byte[size];
                var requestWatch = Stopwatch.StartNew();
                UploadBytes(data);
                requestWatch.Stop();

                totalBytes += size;
                if (requestWatch.Elapsed.TotalSeconds > 0.15)
                {
                    speeds.Add(BytesToMbps(size, requestWatch.Elapsed.TotalSeconds));
                }

                double current = BytesToMbps(totalBytes, totalWatch.Elapsed.TotalSeconds);
                BeginInvoke(new Action(delegate
                {
                    UpdateMain(current, "Upload Speed", "Mbps", current);
                    SetProgress(62 + Math.Min(36, (int)(totalWatch.ElapsedMilliseconds / 10000.0 * 36)), "Testing real upload speed...");
                }));
                index++;
            }

            if (totalBytes == 0) throw new Exception("No upload data was sent");
            return Percentile(speeds, 0.8);
        }

        private void UploadBytes(byte[] data)
        {
            var request = (HttpWebRequest)WebRequest.Create(UploadUrl + "?r=" + Guid.NewGuid().ToString("N"));
            request.Method = "POST";
            request.Timeout = 20000;
            request.ContentLength = data.Length;
            request.ContentType = "application/octet-stream";

            using (var stream = request.GetRequestStream())
            {
                stream.Write(data, 0, data.Length);
            }

            using (var response = (HttpWebResponse)request.GetResponse())
            using (var stream = response.GetResponseStream())
            {
                if (stream != null) stream.ReadByte();
            }
        }

        private async Task TestWebsite()
        {
            websiteButton.Enabled = false;
            websiteResult.Text = "Testing website...";

            try
            {
                string url = websiteInput.Text.Trim();
                if (url.Length == 0) throw new Exception("Enter a website URL first");
                if (!url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
                    !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                {
                    url = "https://" + url;
                }

                WebsiteResult result = await Task.Run(delegate { return MeasureWebsite(url); });
                websiteResult.Text = "Status " + result.StatusCode +
                    " | Total " + result.TotalTimeMs + " ms" +
                    " | First byte " + result.FirstByteTimeMs + " ms" +
                    " | Size " + FormatBytes(result.Bytes);
            }
            catch (Exception ex)
            {
                websiteResult.Text = "Error: " + ex.Message;
            }
            finally
            {
                websiteButton.Enabled = true;
            }
        }

        private WebsiteResult MeasureWebsite(string url)
        {
            var request = (HttpWebRequest)WebRequest.Create(url);
            request.Method = "GET";
            request.Timeout = 15000;
            request.UserAgent = "Network Tester/1.0";

            var watch = Stopwatch.StartNew();
            long bytes = 0;
            long firstByte = -1;
            int status;

            using (var response = (HttpWebResponse)request.GetResponse())
            using (var stream = response.GetResponseStream())
            {
                status = (int)response.StatusCode;
                var buffer = new byte[32 * 1024];
                int read;
                while (stream != null && (read = stream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    if (firstByte < 0) firstByte = watch.ElapsedMilliseconds;
                    bytes += read;
                }
            }

            watch.Stop();
            return new WebsiteResult(status, watch.ElapsedMilliseconds, firstByte < 0 ? 0 : firstByte, bytes);
        }

        private void ResetTest()
        {
            if (isTesting) return;
            speedValue.Text = "0";
            speedUnit.Text = "Mbps";
            speedLabel.Text = "Click Start Test to begin";
            downloadResult.Text = "-- Mbps";
            uploadResult.Text = "-- Mbps";
            pingResult.Text = "-- ms";
            progressBar.Value = 0;
            progressText.Text = "Ready to test real internet speed";
            gauge.Value = 0;
        }

        private void UpdateMain(double value, string label, string unit, double gaugeValue)
        {
            speedValue.Text = value >= 100 ? value.ToString("0") : value.ToString("0.00");
            speedUnit.Text = unit;
            speedLabel.Text = label;
            gauge.Value = gaugeValue;
        }

        private void SetProgress(int value, string text)
        {
            value = Math.Max(0, Math.Min(100, value));
            progressBar.Value = value;
            progressText.Text = text;
        }

        private static double BytesToMbps(long bytes, double seconds)
        {
            if (seconds <= 0) return 0;
            return (bytes * 8.0) / (1024.0 * 1024.0) / seconds;
        }

        private static double Average(List<double> values)
        {
            double sum = 0;
            foreach (double value in values) sum += value;
            return values.Count == 0 ? 0 : sum / values.Count;
        }

        private static double Percentile(List<double> values, double percentile)
        {
            if (values.Count == 0) return 0;
            values.Sort();
            int index = Math.Max(0, Math.Min(values.Count - 1, (int)Math.Ceiling(values.Count * percentile) - 1));
            return values[index];
        }

        private static string FormatBytes(long bytes)
        {
            if (bytes < 1024) return bytes + " B";
            if (bytes < 1024 * 1024) return (bytes / 1024.0).ToString("0.0") + " KB";
            return (bytes / 1024.0 / 1024.0).ToString("0.00") + " MB";
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class GaugeControl : Control
    {
        private double currentValue;

        public double Value
        {
            get { return currentValue; }
            set
            {
                currentValue = Math.Max(0, Math.Min(1000, value));
                Invalidate();
            }
        }

        public GaugeControl()
        {
            DoubleBuffered = true;
            BackColor = Color.FromArgb(245, 248, 251);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            int width = Math.Min(Width - 24, 320);
            int height = Math.Min(Height - 12, 160);
            int left = (Width - width) / 2;
            int top = 10;
            var rect = new Rectangle(left, top, width, height * 2);

            using (var red = new Pen(Color.FromArgb(217, 53, 53), 18))
            using (var yellow = new Pen(Color.FromArgb(242, 184, 75), 18))
            using (var green = new Pen(Color.FromArgb(28, 166, 114), 18))
            using (var blue = new Pen(Color.FromArgb(41, 147, 230), 18))
            {
                e.Graphics.DrawArc(red, rect, 180, 45);
                e.Graphics.DrawArc(yellow, rect, 225, 45);
                e.Graphics.DrawArc(green, rect, 270, 55);
                e.Graphics.DrawArc(blue, rect, 325, 35);
            }

            DrawScale(e.Graphics, left, top, width, height);

            double normalized = Math.Log10(currentValue + 1) / Math.Log10(1001);
            double angle = Math.PI + normalized * Math.PI;
            int centerX = left + width / 2;
            int centerY = top + height;
            int needleLength = width / 2 - 32;
            int endX = centerX + (int)(Math.Cos(angle) * needleLength);
            int endY = centerY + (int)(Math.Sin(angle) * needleLength);

            using (var pen = new Pen(Color.FromArgb(24, 38, 50), 5))
            {
                pen.StartCap = System.Drawing.Drawing2D.LineCap.Round;
                pen.EndCap = System.Drawing.Drawing2D.LineCap.Round;
                e.Graphics.DrawLine(pen, centerX, centerY, endX, endY);
            }

            using (var brush = new SolidBrush(Color.FromArgb(24, 38, 50)))
            {
                e.Graphics.FillEllipse(brush, centerX - 12, centerY - 12, 24, 24);
            }
        }

        private void DrawScale(Graphics graphics, int left, int top, int width, int height)
        {
            string[] labels = { "0", "100", "500", "1G" };
            float[] xs = { left + 8, left + width * 0.32f, left + width * 0.66f, left + width - 32 };
            using (var brush = new SolidBrush(Color.FromArgb(67, 81, 94)))
            using (var font = new Font("Segoe UI", 8, FontStyle.Bold))
            {
                for (int i = 0; i < labels.Length; i++)
                {
                    graphics.DrawString(labels[i], font, brush, xs[i], top + height - 20);
                }
            }
        }
    }

    public class WebsiteResult
    {
        public readonly int StatusCode;
        public readonly long TotalTimeMs;
        public readonly long FirstByteTimeMs;
        public readonly long Bytes;

        public WebsiteResult(int statusCode, long totalTimeMs, long firstByteTimeMs, long bytes)
        {
            StatusCode = statusCode;
            TotalTimeMs = totalTimeMs;
            FirstByteTimeMs = firstByteTimeMs;
            Bytes = bytes;
        }
    }
}
