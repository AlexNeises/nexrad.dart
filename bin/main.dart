// Copyright (c) 2017, Alex Neises. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:nexrad/nexrad.dart';

main() async {
  var nexrad = new Nexrad('/Users/alexneises-2170/IdeaProjects/nexrad/data/KOUN_SDUS54_N0VTLX_201305202016');
  print(nexrad.symbology.sp_af1f_packet.radialData.elementAt(0)['colorValues']);
}