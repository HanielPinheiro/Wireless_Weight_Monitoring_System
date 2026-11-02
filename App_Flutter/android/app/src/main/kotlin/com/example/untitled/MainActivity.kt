package unifesp.sjc.mestrado.haniel.orientador.luiz.galvao.precious.weight

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "bluetooth_helper"
    private val EVENT_CHANNEL = "bluetooth_helper_state"
    private var events: EventChannel.EventSink? = null

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                val isOn = (state == BluetoothAdapter.STATE_ON)
                events?.success(isOn)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel (one-time check)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "isBluetoothOn") {
                val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
                val isOn = bluetoothAdapter?.isEnabled == true
                result.success(isOn)
            } else {
                result.notImplemented()
            }
        }

        // Event channel (state listener)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    this@MainActivity.events = events
                    val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
                    registerReceiver(bluetoothReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(bluetoothReceiver)
                    this@MainActivity.events = null
                }
            }
        )
    }
}
