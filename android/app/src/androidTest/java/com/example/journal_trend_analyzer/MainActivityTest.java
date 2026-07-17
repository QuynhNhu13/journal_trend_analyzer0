package com.example.journal_trend_analyzer;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

// Host JUnit class Patrol dùng để chạy các Dart test trên Android.
//
// Cơ chế: PatrolJUnitRunner khởi động app (MainActivity), chờ PatrolAppService
// bên Dart sẵn sàng, rồi hỏi nó danh sách test qua listDartTests(). Mỗi Dart
// test (vd. "auth_test TC1 - Google Sign-In") trở thành MỘT tham số của lớp
// parametrized này ⇒ mỗi cái là một test case JUnit riêng.
//
// KHÔNG có file này thì testInstrumentationRunner vẫn chạy nhưng không có lớp
// @RunWith nào để parametrize ⇒ Test summary Total: 0.
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
