package com.zomdroid.dualscreen;

import android.view.MotionEvent;
import android.view.View;

import com.zomdroid.input.GLFWBinding;
import com.zomdroid.input.InputNativeInterface;

/**
 * Turns touches on the bottom screen into mouse input on the part of the game canvas shown there.
 * One finger acts as the left mouse button; extra fingers are ignored.
 */
class BottomTouchInput implements View.OnTouchListener {
    /** Game view pixels left of the bottom strip (the top screen's width). */
    private final int canvasLeft;
    /** Size of the bottom strip in game view pixels. */
    private final int canvasWidth, canvasHeight;
    private final float renderScale;
    private int activePointerId = -1;

    BottomTouchInput(int canvasLeft, int canvasWidth, int canvasHeight, float renderScale) {
        this.canvasLeft = canvasLeft;
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;
        this.renderScale = renderScale;
    }

    @Override
    public boolean onTouch(View v, MotionEvent e) {
        int action = e.getActionMasked();
        switch (action) {
            case MotionEvent.ACTION_DOWN: {
                activePointerId = e.getPointerId(0);
                sendPosition(v, e.getX(0), e.getY(0));
                InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, true);
                return true;
            }
            case MotionEvent.ACTION_MOVE: {
                int p = e.findPointerIndex(activePointerId);
                if (p >= 0) sendPosition(v, e.getX(p), e.getY(p));
                return true;
            }
            case MotionEvent.ACTION_POINTER_UP: {
                if (e.getPointerId(e.getActionIndex()) != activePointerId) return true;
                // The pointer holding the button lifted while others stay down: release there.
                sendPosition(v, e.getX(e.getActionIndex()), e.getY(e.getActionIndex()));
                InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, false);
                activePointerId = -1;
                return true;
            }
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL: {
                if (activePointerId >= 0) {
                    int p = e.findPointerIndex(activePointerId);
                    if (p >= 0) sendPosition(v, e.getX(p), e.getY(p));
                    InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, false);
                }
                activePointerId = -1;
                return true;
            }
            default:
                return true;
        }
    }

    private void sendPosition(View v, float x, float y) {
        if (v.getWidth() <= 0 || v.getHeight() <= 0) return;
        float canvasX = canvasLeft + x * canvasWidth / v.getWidth();
        float canvasY = y * canvasHeight / v.getHeight();
        InputNativeInterface.sendCursorPos(canvasX * renderScale, canvasY * renderScale);
    }
}
