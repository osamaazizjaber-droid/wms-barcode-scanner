/* barcode_wrapper.cpp */
extern "C" {
#include "ring.h"
}

#include "QZXing.h"
#include <QImage>
#include <QString>

extern "C" {

RING_FUNC(ring_decode_barcode) {
  if (RING_API_PARACOUNT != 1) {
    RING_API_ERROR(RING_API_MISS1PARA);
    return;
  }

  // Get the QImage pointer from RingQt.
  // Note: RingQt objects usually pass the struct pointer, we extract it.
  // Depending on Ring version, RING_API_GETCPOINTER gets the wrapped pointer.
  void *pImagePtr = RING_API_GETCPOINTER(1, "QImage");
  if (pImagePtr == NULL) {
    RING_API_ERROR("Error: Invalid QImage pointer");
    return;
  }
  QImage *pImg = (QImage *)pImagePtr;

  // Convert to ARGB32 explicitly so CameraImageWrapper extracts pixels
  // correctly
  QImage processedImg = pImg->convertToFormat(QImage::Format_ARGB32);

  QZXing decoder;

  decoder.setDecoder(
      QZXing::DecoderFormat_QR_CODE | QZXing::DecoderFormat_CODE_128 |
      QZXing::DecoderFormat_CODE_39 | QZXing::DecoderFormat_EAN_13 |
      QZXing::DecoderFormat_EAN_8);

  // Test decoding the passed image again, reverting to using QImage directly
  // since we know QImage works. Using ARGB32 because it avoids Grayscale index
  // vs color value ambiguity in older Qt versions.
  QString result = decoder.decodeImage(processedImg);

  std::string resultStr = result.toStdString();

  RING_API_RETSTRING(resultStr.c_str());
}

} // extern "C"
