// Onboarding host: full-screen value carousel -> KYC account opening -> success.
// Revolut full-screen slides, Raiffeisen yellow stamp, Riz buddy throughout.
import { useRouter } from 'expo-router';
import { useRef, useState } from 'react';
import { Dimensions, ScrollView, View } from 'react-native';
import Animated, { FadeIn, SlideInRight } from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import { C, S } from '@/constants/brand';
import { Button, Txt } from '@/components/game/ui';
import { Logo } from '@/components/brand/Logo';
import {
  AiBuddyButton, AiBuddySheet, ConsentRow, Field, KycScreen, LegalSheet, OtpInput, ProgressSegments, SelectField, Toggle,
} from '@/components/onboarding/parts';
import { ILLUSTRATIONS } from '@/components/onboarding/illustrations';
import { KYC_STEPS, SUCCESS, VALUE_SLIDES, stepValid, FieldDef, KycStep } from '@/onboarding/content';
import { CONSENTS, DEPOSIT_INSURANCE, INFORMATION_NOTICE, KYC_AML_NOTICE, LegalDoc, PROTOTYPE_DISCLAIMER } from '@/onboarding/legal';
import { useOnboarding } from '@/onboarding/store';
import { useGame } from '@/game/store';

const W = Dimensions.get('window').width;

const NO_ID_DOC: LegalDoc = {
  id: 'no-id', title: 'No ID card?',
  sections: [
    { body: 'You can also verify with a valid passport or a biometric residence permit.' },
    { heading: 'What we accept', body: 'Albanian national ID card, passport, or biometric residence permit — any current, government-issued photo ID.' },
  ],
};
const READ_DOC: Record<string, LegalDoc> = {
  personal_data_processing: INFORMATION_NOTICE,
  deposit_guarantee_ack: DEPOSIT_INSURANCE,
  kyc_aml_declarations: KYC_AML_NOTICE,
};

function formatDob(s: string): string {
  const d = s.replace(/\D/g, '').slice(0, 8);
  const parts = [d.slice(0, 2), d.slice(2, 4), d.slice(4, 8)].filter(Boolean);
  return parts.join('/');
}

export default function Onboarding() {
  const router = useRouter();
  const ob = useOnboarding();
  const name = useGame((s) => s.name);
  const scroller = useRef<ScrollView>(null);
  const [buddy, setBuddy] = useState<{ open: boolean; seed: boolean }>({ open: false, seed: false });
  const [legal, setLegal] = useState<LegalDoc | null>(null);

  const step = ob.phase === 'kyc' ? KYC_STEPS[ob.stepIndex] : undefined;

  /* ── value carousel ── */
  const onCta = () => {
    if (ob.slideIndex < VALUE_SLIDES.length - 1) {
      const n = ob.slideIndex + 1;
      scroller.current?.scrollTo({ x: n * W, animated: true });
      ob.setSlide(n);
    } else {
      ob.nextSlide(); // -> phase 'kyc'
    }
  };

  const ValueCarousel = (
    <View style={{ flex: 1 }}>
      <View style={{ paddingHorizontal: S.xl, marginBottom: 12, flexDirection: 'row', alignItems: 'center', gap: 10 }}>
        <Logo size={28} />
        <View style={{ flex: 1 }}>
          <Txt variant="eyebrow" color={C.onDarkFaint} upper>Raiffeisen</Txt>
          <Txt variant="h3">Ryze</Txt>
        </View>
      </View>
      <View style={{ paddingHorizontal: S.xl, marginBottom: 8 }}>
        <ProgressSegments count={VALUE_SLIDES.length} active={ob.slideIndex} />
      </View>
      <ScrollView
        ref={scroller} horizontal pagingEnabled showsHorizontalScrollIndicator={false}
        onMomentumScrollEnd={(e) => ob.setSlide(Math.round(e.nativeEvent.contentOffset.x / W))}
        style={{ flex: 1 }}>
        {VALUE_SLIDES.map((slide) => {
          const Illo = ILLUSTRATIONS[slide.illustration];
          return (
            <View key={slide.id} style={{ width: W, paddingHorizontal: S.xl }}>
              <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
                <Illo size={Math.min(W * 0.72, 300)} />
              </View>
              <View style={{ paddingBottom: 8 }}>
                <Txt variant="displayLg" style={{ marginBottom: 12 }}>{slide.title}</Txt>
                <Txt variant="bodyLg" color={C.onDarkMute}>{slide.body}</Txt>
              </View>
            </View>
          );
        })}
      </ScrollView>
      <View style={{ paddingHorizontal: S.xl, paddingTop: 12 }}>
        <Button label={VALUE_SLIDES[ob.slideIndex]?.cta ?? 'Continue'} variant="primary" block onPress={onCta} />
      </View>
    </View>
  );

  /* ── KYC step body ── */
  const renderField = (f: FieldDef) => {
    if (f.type === 'toggle') return <Toggle key={f.key} label={f.label} value={!!ob.toggles[f.key]} onChange={(v) => ob.setToggle(f.key, v)} />;
    if (f.type === 'select' || f.type === 'country')
      return <SelectField key={f.key} label={f.label} value={ob.draft[f.key] ?? ''} options={f.options ?? []} onSelect={(v) => ob.setField(f.key, v)} placeholder="Select" />;
    if (f.type === 'date')
      return <Field key={f.key} label={f.label} value={ob.draft[f.key] ?? ''} onChangeText={(v) => ob.setField(f.key, formatDob(v))} keyboardType="number-pad" placeholder={f.placeholder} error={ob.ageBlock?.reason === 'invalid'} />;
    if (f.type === 'tel')
      return <Field key={f.key} label={f.label} value={ob.draft[f.key] ?? ''} onChangeText={(v) => ob.setField(f.key, v)} keyboardType="phone-pad" prefix="🇦🇱 +355" placeholder={f.placeholder} />;
    return <Field key={f.key} label={f.label} value={ob.draft[f.key] ?? ''} onChangeText={(v) => ob.setField(f.key, v)} keyboardType={f.type === 'email' ? 'email-address' : 'default'} placeholder={f.placeholder} />;
  };

  const stepBody = (st: KycStep) => {
    switch (st.kind) {
      case 'form':
        return (
          <View>
            {(st.fields ?? []).map(renderField)}
            {st.id === 'kyc-dob' && ob.ageBlock && (
              <View style={{ backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline, borderRadius: 16, padding: 16, marginTop: 4 }}>
                <Txt variant="bodyBold" color={C.accent} style={{ marginBottom: 4 }}>Riz</Txt>
                <Txt variant="bodySm" color={C.onDarkMute}>
                  {ob.ageBlock.reason === 'too_young'
                    ? 'Ryze is for ages 18–25, so you’re not eligible just yet — that’s the only reason. Come back when you turn 18.'
                    : 'That date doesn’t look right. Please enter it as DD/MM/YYYY.'}
                </Txt>
              </View>
            )}
          </View>
        );
      case 'otp':
        return (
          <View>
            <OtpInput value={ob.otp[st.otpChannel ?? 'phone'] ?? ''} onChange={(v) => ob.setOtp(st.otpChannel ?? 'phone', v)} />
            <Txt variant="bodySm" color={C.onDarkFaint} style={{ marginTop: 16 }}>Didn’t get it? Resend code in 30s · demo: any 6 digits work</Txt>
          </View>
        );
      case 'intro':
        return <View style={{ alignItems: 'center', marginVertical: 8 }}>{illo(st)}</View>;
      case 'capture':
        return (
          <View style={{ alignItems: 'center' }}>
            {illo(st)}
            <SelectField label="Document type" value={ob.draft.idDocumentType ?? ''} options={st.fields?.[0].options ?? []} onSelect={(v) => ob.setField('idDocumentType', v)} />
            <View style={{ flexDirection: 'row', gap: 10, width: '100%' }}>
              <View style={{ flex: 1 }}><Button label={ob.flags.idFront ? 'Front ✓' : 'Scan front'} variant={ob.flags.idFront ? 'soft' : 'primary'} block onPress={() => ob.markFlag('idFront')} /></View>
              <View style={{ flex: 1 }}><Button label={ob.flags.idBack ? 'Back ✓' : 'Scan back'} variant={ob.flags.idBack ? 'soft' : 'primary'} block onPress={() => ob.markFlag('idBack')} /></View>
            </View>
            <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 12, textAlign: 'center' }}>Camera capture is simulated in this prototype.</Txt>
          </View>
        );
      case 'liveness':
        return (
          <View style={{ alignItems: 'center' }}>
            {illo(st)}
            <Button label={ob.flags.liveness ? 'Verified ✓' : 'Start video check'} variant={ob.flags.liveness ? 'soft' : 'primary'} block onPress={() => ob.markFlag('liveness')} />
            <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 12, textAlign: 'center' }}>Liveness is simulated in this prototype. No human reviews your video.</Txt>
          </View>
        );
      case 'consents':
        return (
          <View>
            {CONSENTS.map((c) => (
              <ConsentRow key={c.id} checked={!!ob.consents[c.id]} onToggle={() => ob.setConsent(c.id, !ob.consents[c.id])}
                label={c.label} onReadMore={READ_DOC[c.id] ? () => setLegal(READ_DOC[c.id]) : undefined} />
            ))}
            <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 12 }}>{PROTOTYPE_DISCLAIMER}</Txt>
          </View>
        );
      case 'permission':
        return <View style={{ alignItems: 'center', marginVertical: 8 }}>{illo(st)}</View>;
      default:
        return null;
    }
  };

  function illo(st: KycStep) {
    if (!st.illustration) return null;
    const Illo = ILLUSTRATIONS[st.illustration];
    return <Illo size={Math.min(W * 0.6, 220)} />;
  }

  const footer = (st: KycStep) => {
    const valid = stepValid(st, ob);
    if (st.kind === 'permission') {
      return (
        <>
          <Button label={st.cta} variant="primary" block onPress={() => ob.next()} />
          <Button label={st.secondaryCta ?? 'Maybe later'} variant="outline" block onPress={() => ob.next()} />
        </>
      );
    }
    return (
      <>
        <Button label={st.cta} variant="primary" block disabled={!valid || ob.submitting} onPress={() => ob.next()} />
        {st.secondaryCta && (
          <Button label={st.secondaryCta} variant="outline" block onPress={() => setLegal(NO_ID_DOC)} />
        )}
      </>
    );
  };

  const KycFlow = step && (
    <Animated.View key={step.id} entering={SlideInRight.duration(280)} style={{ flex: 1, paddingHorizontal: S.xl }}>
      <KycScreen
        title={step.title} body={step.body} why={step.why} onClose={() => ob.back()}
        onWhy={() => setBuddy({ open: true, seed: true })}
        progress={(ob.stepIndex + 1) / KYC_STEPS.length}
        footer={footer(step)}>
        {stepBody(step)}
      </KycScreen>
    </Animated.View>
  );

  const Success = (
    <Animated.View entering={FadeIn.duration(400)} style={{ flex: 1, paddingHorizontal: S.xl, alignItems: 'center', justifyContent: 'center' }}>
      <ILLUSTRATIONS.seal size={Math.min(W * 0.6, 220)} />
      <Txt variant="displayXl" style={{ textAlign: 'center', marginTop: 8, marginBottom: 12 }}>{SUCCESS.title}</Txt>
      <Txt variant="bodyLg" color={C.onDarkMute} style={{ textAlign: 'center', marginBottom: 28 }}>{SUCCESS.body}</Txt>
      <View style={{ alignSelf: 'stretch' }}>
        <Button label={SUCCESS.cta} variant="primary" block onPress={() => router.replace('/')} />
      </View>
    </Animated.View>
  );

  return (
    <View style={{ flex: 1, backgroundColor: C.black }}>
      <SafeAreaView edges={['top', 'bottom']} style={{ flex: 1, paddingVertical: 8 }}>
        {ob.phase === 'value' && ValueCarousel}
        {ob.phase === 'kyc' && KycFlow}
        {ob.phase === 'success' && Success}
      </SafeAreaView>

      {ob.phase !== 'success' && <AiBuddyButton onPress={() => setBuddy({ open: true, seed: false })} />}
      <AiBuddySheet open={buddy.open} onClose={() => setBuddy({ open: false, seed: false })}
        stepId={step?.id} stepTitle={step?.title} name={name} seedWhy={buddy.seed} />
      <LegalSheet open={!!legal} doc={legal} onClose={() => setLegal(null)} />
    </View>
  );
}
