// Copyright (c) 2017, Alex Neises. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class SP_AF1F {
  RadarReader _rr;
  int _pos;
  int indexOfFirstRangeBin;
  int numberOfRangeBins;
  int iCenterOfSweep;
  int jCenterOfSweep;
  double scaleFactor;
  int numberOfRadials;
  List<dynamic> radialData;

  SP_AF1F(RadarReader rr) {
    this._rr = rr;
    this._rr._setPosition(138);
    this._pos = (this._rr._readWord() * 2) + 30 + 18;
    this.indexOfFirstRangeBin = _getIndexOfFirstRangeBin();
    this.numberOfRangeBins = _getNumberOfRangeBins();
    this.iCenterOfSweep = _getICenterOfSweep();
    this.jCenterOfSweep = _getJCenterOfSweep();
    this.scaleFactor = _getScaleFactor();
    this.numberOfRadials = _getNumberOfRadials();
    this.radialData = _getRadialLoop();
  }

  int _getIndexOfFirstRangeBin() {
    int pos = this._pos + 0;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord();
  }

  int _getNumberOfRangeBins() {
    int pos = this._pos + 2;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord();
  }

  int _getICenterOfSweep() {
    int pos = this._pos + 4;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord(true);
  }

  int _getJCenterOfSweep() {
    int pos = this._pos + 6;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord(true);
  }

  double _getScaleFactor() {
    int pos = this._pos + 8;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord() / 1000;
  }

  int _getNumberOfRadials() {
    int pos = this._pos + 10;
    this._rr._setPosition(pos);
    return this._rr._readHalfWord();
  }

  List<Map<String, dynamic>> _getRadialLoop() {
    int pos = this._pos + 12;
    List<Map<String, dynamic>> data = new List<Map<String, dynamic>>();

    for (int i = 0; i < this.numberOfRadials; i++) {
      Map<String, dynamic> rad = new Map<String, dynamic>();
      this._rr._setPosition(pos);
      int numRle = this._rr._readHalfWord();
      rad['numOfRLE'] = numRle;
      pos += 2;
      this._rr._setPosition(pos);
      rad['startAngle'] = this._rr._readHalfWord() / 10.0;
      pos += 2;
      this._rr._setPosition(pos);
      rad['angleDelta'] = this._rr._readHalfWord() / 10.0;
      pos += 2;
      List<int> colorData = new List<int>();
      for (int j = 0; j < numRle * 2; j++) {
        this._rr._setPosition(pos);
        int dt = this._rr._readByte();
        int x = dt >> 4;
        int y = dt & 0x0f;
        for (int z = 0; z < x; z++) {
          colorData.add(y);
        }
        pos++;
      }
      rad['colorValues'] = colorData;
      data.add(rad);
    }
    return data;
  }

  String toString() {
    return 'AF1F:\n'
        '\t\tIndex of First Range Bin: ${this.indexOfFirstRangeBin}\n'
        '\t\tNumber of Range Bins: ${this.numberOfRangeBins}\n'
        '\t\tI Center of Sweep: ${this.iCenterOfSweep}\n'
        '\t\tJ Center of Sweep: ${this.jCenterOfSweep}\n'
        '\t\tScale Factor: ${this.scaleFactor}\n'
        '\t\tNumber of Radials: ${this.numberOfRadials}\n'
        '\t\tRadial: ${this.radialData}\n\n';
  }
}

class Symbology {
  RadarReader _rr;
  int _pos;
  int divider;
  int blockID;
  int blockLength;
  int numberOfLayers;
  int layerDivider;
  int lengthOfDataLayer;
  String packetCode;
  SP_AF1F sp_af1f_packet;

  Symbology(RadarReader rr) {
    this._rr = rr;
    this._rr._setPosition(138);
    this._pos = (this._rr._readWord() * 2) + 30;
    this._rr._setPosition(this._pos + 16);

    this.divider = this._getDivider();
    this.blockID = this._getBlockID();
    this.blockLength = this._getBlockLength();
    this.numberOfLayers = this._getNumberOfLayers();
    this.layerDivider = this._getLayerDivider();
    this.lengthOfDataLayer = this._getLengthOfDataLayer();
    this.packetCode = this._getPacketCode();
    this.sp_af1f_packet = new SP_AF1F(this._rr);
  }

  int _getDivider() {
    this._rr._setPosition(this._pos + 0);
    return this._rr._readHalfWord(true);
  }

  int _getBlockID() {
    this._rr._setPosition(this._pos + 2);
    return this._rr._readHalfWord();
  }

  int _getBlockLength() {
    this._rr._setPosition(this._pos + 4);
    return this._rr._readWord();
  }

  int _getNumberOfLayers() {
    this._rr._setPosition(this._pos + 8);
    return this._rr._readHalfWord();
  }

  int _getLayerDivider() {
    this._rr._setPosition(this._pos + 10);
    return this._rr._readHalfWord(true);
  }

  int _getLengthOfDataLayer() {
    this._rr._setPosition(this._pos + 12);
    return this._rr._readWord();
  }

  String _getPacketCode() {
    this._rr._setPosition(this._pos + 16);
    return this._rr._readHalfWord().toRadixString(16);
  }

  String toString() {
    return 'Symbology:\n'
        '\tDivider: ${this.divider}\n'
        '\tBlock ID: ${this.blockID}\n'
        '\tBlock Length: ${this.blockLength}\n'
        '\tNumber of Layers: ${this.numberOfLayers}\n'
        '\tLayer Divider: ${this.layerDivider}\n'
        '\tLength of Data Layer: ${this.lengthOfDataLayer}\n'
        '\tPacket Code: ${this.packetCode}\n'
        '\t${this.sp_af1f_packet.toString()}\n\n';
  }
}

class Description {
  RadarReader _rr;

  Description(RadarReader rr) {
    this._rr = rr;
  }

  int getDivider() {                          // HW 10
    this._rr._setPosition(48);
    return this._rr._readHalfWord(true);
  }

  double getRadarLatitude() {                 // HW 11-12
    this._rr._setPosition(50);
    return this._rr._readWord(true) / 1000;
  }

  double getRadarLongitude() {                // HW 13-14
    this._rr._setPosition(54);
    return this._rr._readWord(true) / 1000;
  }

  int getRadarHeight() {                      // HW 15
    this._rr._setPosition(58);
    return this._rr._readHalfWord(true);
  }

  int getProductCode() {                      // HW 16
    this._rr._setPosition(60);
    return this._rr._readHalfWord(true);
  }

  int getOperationalMode() {                  // HW 17
    this._rr._setPosition(62);
    return this._rr._readHalfWord();
  }

  int getVolumeCoveragePattern() {            // HW 18
    this._rr._setPosition(64);
    return this._rr._readHalfWord();
  }

  int getSequenceNumber() {                   // HW 19
    this._rr._setPosition(66);
    return this._rr._readHalfWord(true);
  }

  int getVolumeScanNumber() {                 // HW 20
    this._rr._setPosition(68);
    return this._rr._readHalfWord();
  }

  String getVolumeScanDate() {                // HW 21
    this._rr._setPosition(70);
    int days = this._rr._readHalfWord();
    DateTime dt = new DateTime(1970);
    Duration dur = new Duration(days: days);
    DateFormat df = new DateFormat('yyyy-MM-dd');
    return df.format(dt.add(dur));
  }

  String getVolumeScanTime() {                // HW 22-23
    this._rr._setPosition(72);
    int s = this._rr._readWord();
    String date = this.getVolumeScanDate();
    int year = int.parse(date.split('-')[0]);
    int month = int.parse(date.split('-')[1]);
    int day = int.parse(date.split('-')[2]);
    DateTime dt = new DateTime(year, month, day);
    Duration dur = new Duration(seconds: s);
    DateFormat df = new DateFormat('HH:mm:ss');
    return df.format(dt.add(dur));
  }

  String getGenerationDate() {                // HW 24
    this._rr._setPosition(76);
    int days = this._rr._readHalfWord();
    DateTime dt = new DateTime(1970);
    Duration dur = new Duration(days: days);
    DateFormat df = new DateFormat('yyyy-MM-dd');
    return df.format(dt.add(dur));
  }

  String getGenerationTime() {                // HW 25-26
    this._rr._setPosition(78);
    int s = this._rr._readWord();
    String date = this.getVolumeScanDate();
    int year = int.parse(date.split('-')[0]);
    int month = int.parse(date.split('-')[1]);
    int day = int.parse(date.split('-')[2]);
    DateTime dt = new DateTime(year, month, day);
    Duration dur = new Duration(seconds: s);
    DateFormat df = new DateFormat('HH:mm:ss');
    return df.format(dt.add(dur));
  }

  int getProductParameter1() {                // HW 27
    this._rr._setPosition(82);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter2() {                // HW 28
    this._rr._setPosition(84);
    return this._rr._readHalfWord(true);
  }

  int getElevationNumber() {                  // HW 29
    this._rr._setPosition(86);
    return this._rr._readHalfWord();
  }

  int getProductParameter3() {                // HW 30
    this._rr._setPosition(88);
    return this._rr._readHalfWord(true);
  }

  List<String> getDataLevels() {              // HW 31-46
    List<String> data = new List<String>();
    for (int i = 0; i < 32; i += 2) {
      this._rr._setPosition(90 + i);
      data.add(this._rr._readHalfWord().toString());
    }
    return data;
  }

  int getProductParameter4() {                // HW 47
    this._rr._setPosition(122);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter5() {                // HW 48
    this._rr._setPosition(124);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter6() {                // HW 49
    this._rr._setPosition(126);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter7() {                // HW 50
    this._rr._setPosition(128);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter8() {                // HW 51
    this._rr._setPosition(130);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter9() {                // HW 52
    this._rr._setPosition(132);
    return this._rr._readHalfWord(true);
  }

  int getProductParameter10() {               // HW 53
    this._rr._setPosition(134);
    return this._rr._readHalfWord(true);
  }

  int getVersion() {                          // HW 54
    this._rr._setPosition(136);
    return this._rr._readByte();
  }

  int getSpotBlank() {                        // HW 54
    this._rr._setPosition(137);
    return this._rr._readByte();
  }

  int getSymbologyOffset() {                  // HW 55-56
    this._rr._setPosition(138);
    return this._rr._readWord();
  }

  int getGraphicOffset() {                    // HW 57-58
    this._rr._setPosition(142);
    return this._rr._readWord();
  }

  int getTabularOffset() {                    // HW 59-60
    this._rr._setPosition(146);
    return this._rr._readWord();
  }

  String toString() {
    return 'Description:\n'
        '\tDivider: ${this.getDivider()}\n'
        '\tRadar Latitude: ${this.getRadarLatitude()}\n'
        '\tRadar Longitude: ${this.getRadarLongitude()}\n'
        '\tRadar Height: ${this.getRadarHeight()}\n'
        '\tProduct Code: ${this.getProductCode()}\n'
        '\tOperational Mode: ${this.getOperationalMode()}\n'
        '\tVolume Coverage Pattern: ${this.getVolumeCoveragePattern()}\n'
        '\tSequence Number: ${this.getSequenceNumber()}\n'
        '\tVolume Scan Number: ${this.getVolumeScanNumber()}\n'
        '\tVolume Scan Date: ${this.getVolumeScanDate()}\n'
        '\tVolume Scan Time: ${this.getVolumeScanTime()}\n'
        '\tGeneration Date: ${this.getGenerationDate()}\n'
        '\tGeneration Time: ${this.getGenerationTime()}\n'
        '\tProduct Parameter 1: ${this.getProductParameter1()}\n'
        '\tProduct Parameter 2: ${this.getProductParameter2()}\n'
        '\tElevation Number: ${this.getElevationNumber()}\n'
        '\tProduct Parameter 3: ${this.getProductParameter3()}\n'
        '\tData Levels: ${this.getDataLevels()}\n'
        '\tProduct Parameter 4: ${this.getProductParameter4()}\n'
        '\tProduct Parameter 5: ${this.getProductParameter5()}\n'
        '\tProduct Parameter 6: ${this.getProductParameter6()}\n'
        '\tProduct Parameter 7: ${this.getProductParameter7()}\n'
        '\tProduct Parameter 8: ${this.getProductParameter8()}\n'
        '\tProduct Parameter 9: ${this.getProductParameter9()}\n'
        '\tProduct Parameter 10: ${this.getProductParameter10()}\n'
        '\tVersion: ${this.getVersion()}\n'
        '\tSpot Blank: ${this.getSpotBlank()}\n'
        '\tSymbology Offset: ${this.getSymbologyOffset()}\n'
        '\tGraphic Offset: ${this.getGraphicOffset()}\n'
        '\tTabular Offset: ${this.getTabularOffset()}\n\n';
  }
}

class Header {
  RadarReader _rr;

  Header(RadarReader rr) {
    this._rr = rr;
  }

  int getMessageCode() {
    this._rr._setPosition(30);
    return this._rr._readHalfWord(true);
  }

  String getMessageDate() {
    this._rr._setPosition(32);
    int days = this._rr._readHalfWord();
    DateTime dt = new DateTime(1970);
    Duration dur = new Duration(days: days);
    DateFormat df = new DateFormat('yyyy-MM-dd');
    return df.format(dt.add(dur));
  }

  String getMessageTime() {
    this._rr._setPosition(34);
    int s = this._rr._readWord();
    String date = this.getMessageDate();
    int year = int.parse(date.split('-')[0]);
    int month = int.parse(date.split('-')[1]);
    int day = int.parse(date.split('-')[2]);
    DateTime dt = new DateTime(year, month, day);
    Duration dur = new Duration(seconds: s);
    DateFormat df = new DateFormat('HH:mm:ss');
    return df.format(dt.add(dur));
  }

  int getMessageLength() {
    this._rr._setPosition(38);
    return this._rr._readWord();
  }

  int getSourceID() {
    this._rr._setPosition(42);
    return this._rr._readHalfWord();
  }

  int getDestinationID() {
    this._rr._setPosition(44);
    return this._rr._readHalfWord();
  }

  int getNumberOfBlocks() {
    this._rr._setPosition(46);
    return this._rr._readHalfWord();
  }

  String toString() {
    return 'Header:\n'
        '\tMessage Code: ${this.getMessageCode()}\n'
        '\tMessage Date: ${this.getMessageDate()}\n'
        '\tMessage Time: ${this.getMessageTime()}\n'
        '\tMessage Length: ${this.getMessageLength()}\n'
        '\tSource ID: ${this.getSourceID()}\n'
        '\tDestination ID: ${this.getDestinationID()}\n'
        '\tNumber of Blocks: ${this.getNumberOfBlocks()}\n\n';
  }
}

class Nexrad {
  ByteData _data;
  Header header;
  Description description;
  Symbology symbology;

  Nexrad(String file) {
    File myFile = new File(file);
    List<int> fileBytes = myFile.readAsBytesSync();
    ByteBuffer buffer = new Int8List.fromList(fileBytes).buffer;
    RadarReader rr = new RadarReader(new ByteData.view(buffer));
    this.header = new Header(rr);
    this.description = new Description(rr);
    this.symbology = new Symbology(rr);
  }

  String toString() {
    return this.header.toString() + this.description.toString() + this.symbology.toString();
  }
}

class RadarReader {
  ByteData _data;
  int _position;

  RadarReader(ByteData data) {
    this._data = data;
  }

  void _setPosition(int pos) {
    this._position = pos;
  }

  int _readByte([bool signed = false]) {
    if (signed == false) {
      return this._data.getUint8(this._position);
    } else {
      return this._data.getInt8(this._position);
    }
  }

  int _readHalfWord([bool signed = false, bool bigEndian = true]) {
    if (signed == false) {
      if (bigEndian == true) {
        return this._data.getUint16(this._position, Endianness.BIG_ENDIAN);
      } else {
        return this._data.getUint16(this._position, Endianness.LITTLE_ENDIAN);
      }
    } else {
      if (bigEndian == true) {
        return this._data.getInt16(this._position, Endianness.BIG_ENDIAN);
      } else {
        return this._data.getInt16(this._position, Endianness.LITTLE_ENDIAN);
      }
    }
  }

  int _readWord([bool signed = false, bool bigEndian = true]) {
    if (signed == false) {
      if (bigEndian == true) {
        return this._data.getUint32(this._position, Endianness.BIG_ENDIAN);
      } else {
        return this._data.getUint32(this._position, Endianness.LITTLE_ENDIAN);
      }
    } else {
      if (bigEndian == true) {
        return this._data.getInt32(this._position, Endianness.BIG_ENDIAN);
      } else {
        return this._data.getInt32(this._position, Endianness.LITTLE_ENDIAN);
      }
    }
  }
}