// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class NativeAdFactoryExample implements NativeAdFactory {
//   @override
//   Widget createNativeAd(
//       NativeAd ad, {
//         required Map<String, dynamic> customOptions,
//       }) {
//     return Container(
//       height: 260.h,
//       width: 160.w,
//       margin: EdgeInsets.only(right: 16.w),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(12.r),
//       ),
//       child: Card(
//         margin: EdgeInsets.zero,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
//               child: Container(
//                 height: 160.h,
//                 width: double.infinity,
//                 child: ad.mediaContent != null && ad.mediaContent!.hasVideoContent
//                     ? AspectRatio(
//                   aspectRatio: ad.mediaContent!.aspectRatio ?? 16 / 9,
//                   child: AdWidget(ad: ad),
//                 )
//                     : ad.images.isNotEmpty
//                     ? Image.memory(
//                   ad.images.first.data!,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) => Image.asset(
//                     'assets/images/placeholder.jpg',
//                     fit: BoxFit.cover,
//                   ),
//                 )
//                     : Image.asset(
//                   'assets/images/placeholder.jpg',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(8.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 20.h,
//                     child: Text(
//                       ad.headline ?? 'Sponsored',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         color: Colors.orange[300],
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   SizedBox(height: 4.h),
//                   Container(
//                     height: 32.h,
//                     child: Text(
//                       ad.body ?? 'Ad',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: Colors.grey[300],
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: Padding(
//                 padding: EdgeInsets.all(8.w),
//                 child: Text(
//                   'Ad',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }