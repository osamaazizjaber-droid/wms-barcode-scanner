/* barcode_wrapper.cpp */
extern "C" {
#include "ring.h"
}

#include "QZXing.h"
#include <QImage>
#include <QString>

// Separate C++ implementation specifically to avoid extern "C" mangling on
// QZXing templates
static std::string decode_barcode_impl(QImage *pImg) {
  QImage processedImg = pImg->convertToFormat(QImage::Format_ARGB32);
  QZXing decoder;
  decoder.setDecoder(
      QZXing::DecoderFormat_QR_CODE | QZXing::DecoderFormat_CODE_128 |
      QZXing::DecoderFormat_CODE_39 | QZXing::DecoderFormat_EAN_13 |
      QZXing::DecoderFormat_EAN_8);

  QString result = decoder.decodeImage(processedImg);
  return result.toStdString();
}

extern "C" {

RING_FUNC(ring_decode_barcode) {
  if (RING_API_PARACOUNT != 1) {
    RING_API_ERROR(RING_API_MISS1PARA);
    return;
  }

  void *pImagePtr = RING_API_GETCPOINTER(1, "QImage");
  if (pImagePtr == NULL) {
    RING_API_ERROR("Error: Invalid QImage pointer");
    return;
  }

  QImage *pImg = (QImage *)pImagePtr;
  std::string resultStr = decode_barcode_impl(pImg);
  RING_API_RETSTRING(resultStr.c_str());
}

} // extern "C"
