using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.ActivityMonitor as Act;
using Toybox.Math as Math;

class minimal_venu3_faceView extends Ui.WatchFace {
    var _dc;
    var _w, _h, _cx, _cy;

    // Bitmaps (precargados)
    var iconHeart;
    var iconSteps;
    var iconFlame;
    var iconNotif;
    var iconSun;
    var iconMoon;
    var bg;
    var fg;

    function initialize() {
        Ui.WatchFace.initialize();

        // Cargar recursos (un solo parámetro: ResourceId)
        iconHeart = Ui.loadResource(Rez.Drawables.icon_heart);
        iconSteps = Ui.loadResource(Rez.Drawables.icon_steps);
        iconFlame = Ui.loadResource(Rez.Drawables.icon_flame);
        iconNotif = Ui.loadResource(Rez.Drawables.icon_notif);
        iconSun   = Ui.loadResource(Rez.Drawables.icon_sun);
        iconMoon  = Ui.loadResource(Rez.Drawables.icon_moon);
    }

    function onLayout(dc as Gfx.Dc) as Void {
        _dc = dc;
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = (_w / 2).toNumber();
        _cy = (_h / 2).toNumber();
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        _dc = dc;

        bg = getApp().getProperty("BackgroundColor") as Number;
        fg = getApp().getProperty("ForegroundColor") as Number;

        // 1) Fondo
        dc.setColor(fg, bg);
        dc.clear();
        dc.setColor(fg, bg);

        // 2) Dial (marcas)
        drawDial(dc);

        // 3) Iconos + textos (quedarán debajo de las manecillas)
        var g = Greg.info(Time.now(), Time.FORMAT_SHORT);
        dc.setColor(fg, Gfx.COLOR_TRANSPARENT);

        // Sol/Luna centrado (iconos 28px → offset 14 para centrar)
        var dayNightBmp = (g.hour >= 6 && g.hour < 18) ? iconSun : iconMoon;
        // dc.drawBitmap(_cx - 65, _cy - 120, dayNightBmp);

        // Fecha
        var dateStr = weekdayShort(g.day_of_week - 1) + " " + g.day + " " + monthShort(g.month);
        // dc.drawText(_cx, _cy + 110, Gfx.FONT_XTINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(_cx - 50, _cy + 110, Gfx.FONT_XTINY, weekdayShort(g.day_of_week - 1), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(_cx - 50, _cy + 140, Gfx.FONT_XTINY, g.day, Gfx.TEXT_JUSTIFY_CENTER);

        // Hora digital (HH:MM), formato según ajuste UseMilitaryFormat
        var useMilitary = getApp().getProperty("UseMilitaryFormat") as Boolean;
        var digital = hourString(g.hour, useMilitary) + ":" + (g.min < 10 ? "0" + g.min : g.min.toString());
        dc.drawText(_cx + 40, _cy + 112, Gfx.FONT_XTINY, digital, Gfx.TEXT_JUSTIFY_CENTER);

        // Métricas (tolerantes a permisos/modelo)
        var stepsStr = "--";
        var calsStr  = "--";
        var hrStr    = "--";
        try {
            var info = Act.getInfo();
            if (info != null) {
                if (info.steps != null)     { stepsStr = info.steps.toString(); }
                if (info.calories != null)  { calsStr  = info.calories.toString(); }
                // Descomenta si tu dispositivo expone HR en watchface con tus permisos:
                // if (info.currentHeartRate != null)      { hrStr = info.currentHeartRate.toString(); }
                // else if (info.heartRate != null)        { hrStr = info.heartRate.toString(); }
                // else if (info.averageHeartRate != null) { hrStr = info.averageHeartRate.toString(); }
            }
        } catch(e) { }

        // Notificaciones (placeholder; si tienes una API real, cámbialo)
        var notifications = 0;

        // Columna izquierda con iconos 28px + texto alineado
        var ix = 18;             // x icono
        var tx = ix + 30;        // x texto
        var y0 = _cy - 26;       // y base
        var dy = 28;             // salto por fila (≈ alto icono)

        // Notifs
        dc.drawBitmap(70, 100, iconNotif);
        dc.drawText  (100, 100, Gfx.FONT_XTINY, notifications.toString(), Gfx.TEXT_JUSTIFY_LEFT);

        // Steps
        dc.drawBitmap(320, 100, iconSteps);
        dc.drawText  (350, 100, Gfx.FONT_XTINY, stepsStr, Gfx.TEXT_JUSTIFY_LEFT);

        // Calories
        dc.drawBitmap(280, 202, iconFlame);
        dc.drawText  (310, 200, Gfx.FONT_XTINY, calsStr, Gfx.TEXT_JUSTIFY_LEFT);

        // Heart Rate
        dc.drawBitmap(100, 202, iconHeart);
        dc.drawText  (130, 200, Gfx.FONT_XTINY, hrStr, Gfx.TEXT_JUSTIFY_LEFT);

        // 4) Manecillas (AL FINAL, para quedar encima de todo)
        drawHands(dc, g);
    }

    // ----- Dibujo del dial (marcas) -----
    // function drawDial(dc as Gfx.Dc) as Void {
    //     dc.setColor(Gfx.COLOR_WHITE, bg);
    //     var base = (_w < _h ? _w : _h);

    //     // Marcas de horas pegadas al borde
    //     var outerR = (base / 2) - 6; // margen 6px
    //     var innerR = outerR - 10;    // longitud de la marca
    //     dc.setPenWidth(3);
    //     for (var i = 0; i < 12; i += 1) {
    //         var angle = (i / 12.0) * 2.0 * Math.PI;
    //         var x1 = _cx + innerR * Math.sin(angle);
    //         var y1 = _cy - innerR * Math.cos(angle);
    //         var x2 = _cx + outerR * Math.sin(angle);
    //         var y2 = _cy - outerR * Math.cos(angle);
    //         dc.drawLine(x1, y1, x2, y2);
    //     }
    //     dc.setPenWidth(1);
    // }

    function drawDial(dc as Gfx.Dc) as Void {
        // dibujamos las marcas con el color de primer plano configurado, fondo TRANSPARENTE
        dc.setColor(fg, Gfx.COLOR_TRANSPARENT);

        var base   = (_w < _h ? _w : _h);
        var outerR = (base / 2) - 6;

        // --- marcas de minutos (60, finitas) ---
        var innerRmin = outerR - 14;   // longitud corta
        dc.setPenWidth(1);            // mínimo válido
        for (var i = 0; i < 60; i += 1) {
            var angle = (i / 60.0) * 2.0 * Math.PI;
            var x1 = _cx + innerRmin * Math.sin(angle);
            var y1 = _cy - innerRmin * Math.cos(angle);
            var x2 = _cx + outerR    * Math.sin(angle);
            var y2 = _cy - outerR    * Math.cos(angle);
            dc.drawLine(x1, y1, x2, y2);
        }

        // --- marcas de horas (12, un poco más largas/gruesas) ---
        var innerRhr = outerR - 19;
        dc.setPenWidth(5);
        for (var j = 0; j < 12; j += 1) {
            var a = (j / 12.0) * 2.0 * Math.PI;
            var hx1 = _cx + innerRhr * Math.sin(a);
            var hy1 = _cy - innerRhr * Math.cos(a);
            var hx2 = _cx + outerR   * Math.sin(a);
            var hy2 = _cy - outerR   * Math.cos(a);
            dc.drawLine(hx1, hy1, hx2, hy2);
        }

        dc.setPenWidth(1); // restaurar
    }

    // ----- Dibujo de manecillas -----
    // function drawHands(dc as Gfx.Dc, g) as Void {
    //     var base = (_w < _h ? _w : _h);

    //     var sec = g.sec;
    //     var min = g.min + sec / 60.0;
    //     var hr  = (g.hour % 12) + min / 60.0;

    //     var secAng = (sec / 60.0) * 2 * Math.PI;
    //     var minAng = (min / 60.0) * 2 * Math.PI;
    //     var hrAng  = (hr  / 12.0) * 2 * Math.PI;

    //     // Hora y minutos
    //     drawHand(dc, hrAng,  base * 0.28, 6);
    //     drawHand(dc, minAng, base * 0.40, 5);

    //     // Segundero
    //     dc.setColor(Gfx.COLOR_WHITE, bg);
    //     drawHand(dc, secAng, base * 0.46, 1);
    // }

    function drawHands(dc as Gfx.Dc, g) as Void {
    var base = (_w < _h ? _w : _h);

    var sec = g.sec;
    var min = g.min + sec / 60.0;
    var hr  = (g.hour % 12) + min / 60.0;

    var secAng = (sec / 60.0) * 2 * Math.PI;
    var minAng = (min / 60.0) * 2 * Math.PI;
    var hrAng  = (hr  / 12.0) * 2 * Math.PI;

    // Hora y minutos
    drawHand(dc, hrAng,  base * 0.28, 6);
    drawHand(dc, minAng, base * 0.40, 5);

    // Segundero
    dc.setColor(fg, bg);
    drawHand(dc, secAng, base * 0.46, 1);

    // --- Hub central (aro + punto) ---
    dc.setColor(fg, Gfx.COLOR_TRANSPARENT);
    dc.fillCircle(_cx, _cy, 11);        // círculo exterior con color de primer plano
    dc.setColor(bg, Gfx.COLOR_TRANSPARENT);
    dc.fillCircle(_cx, _cy, 3);        // relleno con el color de fondo
}

    function drawHand(dc as Gfx.Dc, angle, length, width) as Void {
        var x = _cx + length * Math.sin(angle);
        var y = _cy - length * Math.cos(angle);
        dc.setPenWidth(width);
        dc.drawLine(_cx, _cy, x, y);
        dc.setPenWidth(1);
    }

    // Utilidades de texto fecha
    function weekdayShort(w) {
        var arr = ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"];
        return arr[w % 7];
    }

    function monthShort(m) {
        var arr = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"];
        return arr[(m - 1) % 12];
    }

    // Formatea la hora respetando la propiedad UseMilitaryFormat (24h vs 12h)
    function hourString(hour as Number, useMilitary as Boolean) as String {
        if (useMilitary) {
            return (hour < 10 ? "0" + hour : hour.toString());
        }
        var h12 = hour % 12;
        if (h12 == 0) {
            h12 = 12;
        }
        return h12.toString();
    }

    function onPartialUpdate(dc as Gfx.Dc) as Void {
        onUpdate(dc);
    }
}