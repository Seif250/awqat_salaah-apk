package com.awqatsalaah.awqat_salaah

import io.flutter.app.FlutterApplication

class AwqatSalaahApp : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        AdhanSilencer.init(this)
    }
}
