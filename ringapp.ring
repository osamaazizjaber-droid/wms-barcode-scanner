load "guilib.ring"
load "ringqml.ring"
if iswindows()
    loadlib("ring_barcode.dll")
ok
load "qtdownload.ring"

# ===================================================================
# INSTRUCTIONS FOR DEPLOYMENT:
# Replace the $script_url below with your own Google Apps Script Web App URL
# ===================================================================
$script_url = "YOUR_GOOGLE_APPS_SCRIPT_WEB_APP_URL_HERE"

oApp = new qApp

$oBridge = new qLineEdit(NULL)
$oQML = new RingQML(NULL)
$oQML.ShareWidget($oBridge, "ringBridge")

$oQML.loadContent(read("main.qml"))
oApp.exec()

# ============================================================
# BACKEND FUNCTIONS (Called by QML via Ring.callFunc)
# ============================================================

func backend_processCameraImage filepath
    # Convert file URL from QML (e.g. file:///C:/...) to normal path
    if substr(filepath, 1, 8) = "file:///"
        filepath = substr(filepath, 9)
        # On Windows, keep the drive letter, e.g., C:/...
    ok
    
    process_scanned_file(filepath, 0)
    return

func backend_autoScanImage filepath
    if substr(filepath, 1, 8) = "file:///"
        filepath = substr(filepath, 9)
    ok
    process_scanned_file(filepath, 1)
    return

func process_scanned_file filepath, is_auto
    p = new qPixmap(filepath)
    if p.isnull()
        if not is_auto
            $oBridge.setText("toast:Processing failed (Null Image)")
        ok
        return
    ok
    
    img2 = p.toImage()
    
    # QZXing works best explicitly with ARGB32, which is handled natively by the DLL wrapper.
    # Pass the image directly.
    result = decode_barcode(img2.pObject)

    if result != ""
        if left(result, 1) = "*" and right(result, 1) = "*"
            result = substr(result, 2, len(result)-2)
        ok
        $oBridge.setText("barcode:" + result)
    else
        if not is_auto
            $oBridge.setText("toast:No barcode found in image")
        ok
    ok
    return


func backend_saveData barcode, date_time, overtime_hours, notes
    # Check if URL is updated
    if $script_url = "YOUR_GOOGLE_APPS_SCRIPT_WEB_APP_URL_HERE"
        $oBridge.setText("save_result:0;Please set Google Apps Script URL in backend.")
        return
    ok

    $oBridge.setText("toast:Saving to Google Sheets...")

    # Build params string manually avoiding encodeURIComponent since we need a Ring function
    params = "barcode=" + escape(barcode) + "&datetime=" + escape(date_time) + "&overtime=" + escape(""+overtime_hours) + "&notes=" + escape(notes)

    qtdownload([
        :url = $script_url,
        :method = "POST",
        :headers = ["Content-Type: application/x-www-form-urlencoded"],
        :body = params,
        :callback = func n,res {
            # Google Apps script typically returns 302 or 200
            if n >= 200 and n < 400
                $oBridge.setText("save_result:1;Success")
            else
                $oBridge.setText("save_result:0;HTTP Error: " + n)
            ok
        }
    ])
    return

func escape str
    str_esc = ""
    for i = 1 to len(str)
        c = substr(str, i, 1)
        if isalnum(c) or c = " " or c = "-" or c = ":"
            if c = " " 
                str_esc += "%20"
            else
                str_esc += c
            ok
        else
            str_esc += "%" + hex(ascii(c))
        ok
    next
    return str_esc
