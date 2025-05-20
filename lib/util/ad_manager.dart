import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rxdart/rxdart.dart';

class AdManager {
  static const String _bannerAdUnitId = 'ca-app-pub-8669730468623760/1806673128';
  static const String _nativeAdUnitId = 'ca-app-pub-8669730468623760/7261954441';

  BannerAd? _bannerAd;
  final _isBannerAdLoadedSubject = BehaviorSubject<bool>.seeded(false);
  final _bannerAdSubject = BehaviorSubject<BannerAd?>.seeded(null);

  NativeAd? _nativeAd;
  final _isNativeAdLoadedSubject = BehaviorSubject<bool>.seeded(false);
  final _nativeAdSubject = BehaviorSubject<NativeAd?>.seeded(null);

  Stream<bool> get isBannerAdLoadedStream => _isBannerAdLoadedSubject.stream;
  Stream<BannerAd?> get bannerAdStream => _bannerAdSubject.stream;
  Stream<bool> get isNativeAdLoadedStream => _isNativeAdLoadedSubject.stream;
  Stream<NativeAd?> get nativeAdStream => _nativeAdSubject.stream;

  void loadBannerAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailed}) {
    print('Attempting to load banner ad with unit ID: ${kDebugMode ? 'ca-app-pub-3940256099942544/6300978111' : _bannerAdUnitId}');
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: kDebugMode ? 'ca-app-pub-3940256099942544/6300978111' : _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('Banner ad loaded successfully');
          _isBannerAdLoadedSubject.add(true);
          _bannerAdSubject.add(_bannerAd);
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Banner ad failed to load: $error (Code: ${error.code}, Message: ${error.message})');
          _isBannerAdLoadedSubject.add(false);
          _bannerAdSubject.add(null);
          _bannerAd?.dispose();
          _bannerAd = null;
          onAdFailed?.call();
        },
        onAdOpened: (Ad ad) => print('Banner ad opened'),
        onAdClosed: (Ad ad) => print('Banner ad closed'),
        onAdImpression: (Ad ad) => print('Banner ad impression'),
      ),
    );
    _bannerAd!.load();
  }

  void loadNativeAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailed}) {
    print('Attempting to load native ad with unit ID: ${kDebugMode ? 'ca-app-pub-3940256099942544/2247696110' : _nativeAdUnitId}');
    _nativeAd?.dispose();
    _nativeAd = NativeAd(
      adUnitId: kDebugMode ? 'ca-app-pub-3940256099942544/2247696110' : _nativeAdUnitId,
      factoryId: 'adFactoryExample',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          print('Native ad loaded successfully: ${ad.adUnitId}');
          _isNativeAdLoadedSubject.add(true);
          _nativeAdSubject.add(_nativeAd);
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Native ad failed to load: $error (Code: ${error.code}, Message: ${error.message})');
          _isNativeAdLoadedSubject.add(false);
          _nativeAdSubject.add(null);
          _nativeAd?.dispose();
          _nativeAd = null;
          onAdFailed?.call();
        },
        onAdOpened: (Ad ad) => print('Native ad opened'),
        onAdClosed: (Ad ad) => print('Native ad closed'),
        onAdImpression: (Ad ad) => print('Native ad impression'),
      ),
    );
    _nativeAd!.load();
  }

  void dispose() {
    print('Disposing AdManager...');
    _bannerAd?.dispose();
    _bannerAd = null;
    _nativeAd?.dispose();
    _nativeAd = null;
    _isBannerAdLoadedSubject.close();
    _bannerAdSubject.close();
    _isNativeAdLoadedSubject.close();
    _nativeAdSubject.close();
  }
}