package com.zomdroid.dualscreen;

import android.os.Handler;
import android.os.Looper;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;

import com.zomdroid.input.GLFWBinding;
import com.zomdroid.input.InputNativeInterface;

/**
 * Turns touches on the bottom screen into mouse input on the part of the game canvas shown there.
 *
 * <ul>
 * <li>Tap: left click.</li>
 * <li>Drag (moves past the touch slop): left button held from where the finger went down, so
 *     items, scrollbars and window title bars can be dragged.</li>
 * <li>Long press without moving: right click (context menus).</li>
 * <li>Two fingers moving up/down: mouse wheel.</li>
 * </ul>
 *
 * The left button is only pressed once the gesture is known, so a long press never clicks the
 * thing under the finger first.
 */
class BottomTouchInput implements View.OnTouchListener {
    private enum State { IDLE, PENDING, DRAGGING, LONG_PRESSED, SCROLLING }

    /** View pixels the two fingers travel per wheel notch. */
    private static final float SCROLL_STEP_PX = 40f;
    /**
     * How long a tap or long-press click holds the button. The game samples button state once per
     * frame, so a press and release sent together are never seen.
     */
    private static final long CLICK_HOLD_MS = 50;

    /** Game view pixels left of the bottom strip (the top screen's width). */
    private final int canvasLeft;
    /** Size of the bottom strip in game view pixels. */
    private final int canvasWidth, canvasHeight;
    private final float renderScale;
    private final Handler handler = new Handler(Looper.getMainLooper());

    private State state = State.IDLE;
    private View view;
    private int activePointerId = -1;
    private float downX, downY;
    private float scrollLastY, scrollAccum;
    private int touchSlop = -1;
    private int heldButton = -1;

    private final Runnable releaseClick = () -> {
        if (heldButton >= 0) {
            InputNativeInterface.sendMouseButton(heldButton, false);
            heldButton = -1;
        }
    };

    private final Runnable longPress = () -> {
        if (state != State.PENDING) return;
        state = State.LONG_PRESSED;
        sendPosition(downX, downY);
        click(GLFWBinding.MOUSE_BUTTON_RIGHT.code);
        if (view != null) view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
    };

    BottomTouchInput(int canvasLeft, int canvasWidth, int canvasHeight, float renderScale) {
        this.canvasLeft = canvasLeft;
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;
        this.renderScale = renderScale;
    }

    @Override
    public boolean onTouch(View v, MotionEvent e) {
        view = v;
        if (touchSlop < 0) touchSlop = ViewConfiguration.get(v.getContext()).getScaledTouchSlop();

        switch (e.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                finishClick();
                activePointerId = e.getPointerId(0);
                downX = e.getX(0);
                downY = e.getY(0);
                state = State.PENDING;
                // Hover first: the game shows tooltips and highlights under the cursor.
                sendPosition(downX, downY);
                handler.postDelayed(longPress, ViewConfiguration.getLongPressTimeout());
                return true;

            case MotionEvent.ACTION_POINTER_DOWN:
                if (e.getPointerCount() == 2 && (state == State.PENDING || state == State.DRAGGING)) {
                    handler.removeCallbacks(longPress);
                    if (state == State.DRAGGING) releaseLeft(e);
                    state = State.SCROLLING;
                    scrollLastY = (e.getY(0) + e.getY(1)) / 2f;
                    scrollAccum = 0f;
                }
                return true;

            case MotionEvent.ACTION_MOVE: {
                if (state == State.SCROLLING) {
                    if (e.getPointerCount() >= 2) scroll((e.getY(0) + e.getY(1)) / 2f);
                    return true;
                }
                int p = e.findPointerIndex(activePointerId);
                if (p < 0) return true;
                float x = e.getX(p), y = e.getY(p);
                if (state == State.PENDING && Math.hypot(x - downX, y - downY) > touchSlop) {
                    handler.removeCallbacks(longPress);
                    state = State.DRAGGING;
                    // Press where the finger went down so the drag starts on what was touched.
                    sendPosition(downX, downY);
                    InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, true);
                }
                if (state == State.DRAGGING) sendPosition(x, y);
                return true;
            }

            case MotionEvent.ACTION_POINTER_UP:
                if (state != State.SCROLLING && e.getPointerId(e.getActionIndex()) == activePointerId) {
                    finishSinglePointer(e, e.getActionIndex());
                }
                return true;

            case MotionEvent.ACTION_UP:
                if (state == State.SCROLLING || state == State.LONG_PRESSED) {
                    state = State.IDLE;
                } else {
                    int p = e.findPointerIndex(activePointerId);
                    finishSinglePointer(e, p >= 0 ? p : 0);
                }
                activePointerId = -1;
                return true;

            case MotionEvent.ACTION_CANCEL:
                handler.removeCallbacks(longPress);
                if (state == State.DRAGGING) releaseLeft(e);
                state = State.IDLE;
                activePointerId = -1;
                return true;

            default:
                return true;
        }
    }

    private void scroll(float y) {
        scrollAccum += y - scrollLastY;
        scrollLastY = y;
        // Fingers moving down pull the content down, like a touch list: wheel up.
        while (scrollAccum >= SCROLL_STEP_PX) {
            scrollAccum -= SCROLL_STEP_PX;
            InputNativeInterface.sendMouseScroll(0.0, 1.0);
        }
        while (scrollAccum <= -SCROLL_STEP_PX) {
            scrollAccum += SCROLL_STEP_PX;
            InputNativeInterface.sendMouseScroll(0.0, -1.0);
        }
    }

    /** The pointer driving a tap or drag lifted. */
    private void finishSinglePointer(MotionEvent e, int index) {
        handler.removeCallbacks(longPress);
        if (state == State.PENDING) {
            sendPosition(downX, downY);
            click(GLFWBinding.MOUSE_BUTTON_LEFT.code);
        } else if (state == State.DRAGGING) {
            sendPosition(e.getX(index), e.getY(index));
            InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, false);
        }
        state = State.IDLE;
    }

    /** Press a button now and release it after {@link #CLICK_HOLD_MS}. */
    private void click(int button) {
        finishClick();
        InputNativeInterface.sendMouseButton(button, true);
        heldButton = button;
        handler.postDelayed(releaseClick, CLICK_HOLD_MS);
    }

    /** Release a click still being held, before anything else touches the buttons. */
    private void finishClick() {
        handler.removeCallbacks(releaseClick);
        releaseClick.run();
    }

    private void releaseLeft(MotionEvent e) {
        int p = e.findPointerIndex(activePointerId);
        if (p >= 0) sendPosition(e.getX(p), e.getY(p));
        InputNativeInterface.sendMouseButton(GLFWBinding.MOUSE_BUTTON_LEFT.code, false);
    }

    private void sendPosition(float x, float y) {
        if (view == null || view.getWidth() <= 0 || view.getHeight() <= 0) return;
        float canvasX = canvasLeft + x * canvasWidth / view.getWidth();
        float canvasY = y * canvasHeight / view.getHeight();
        InputNativeInterface.sendCursorPos(canvasX * renderScale, canvasY * renderScale);
    }
}
