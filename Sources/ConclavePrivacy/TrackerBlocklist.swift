import Foundation

/// Registrable domains of widely deployed advertising and analytics networks.
/// Requests to these domains (and their subdomains) are blocked when they are
/// made from a different site.
public enum TrackerBlocklist {
    public static let domains: [String] = [
        // Google advertising and analytics
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "googletagmanager.com", "googletagservices.com",
        "adservice.google.com",
        // Meta, Microsoft, Amazon, X, TikTok
        "facebook.net", "connect.facebook.com", "clarity.ms", "bat.bing.com",
        "amazon-adsystem.com", "ads-twitter.com", "analytics.tiktok.com",
        "ads.linkedin.com", "snap.licdn.com",
    ]
}
