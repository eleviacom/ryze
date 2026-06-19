// Corrected legal copy for Ryze (Raiffeisen Bank Sh.a., Albania).
// Verified via the onboarding research workflow (web-grounded + fact-checked):
//   - Data protection: Law No. 124/2024 (repealed 9887/2008), regulator IDP.
//   - Deposit insurance: ASD, Law No. 53/2014, 100% up to 2,500,000 ALL per depositor/bank.
//   - AML: Law No. 9917/2008; recipient = Financial Intelligence Agency (AIF).
//   - Tax: CRS (Law 4/2020) + FATCA; Albania-only resident identifier = personal NID (not NIPT).
//   - Capacity: Civil Code Art. 6 — full capacity at 18.
// PROTOTYPE: final wording must be replaced verbatim with the Bank's approved documents.

export const PROTOTYPE_DISCLAIMER =
  'Ryze is a hackathon prototype concept for Raiffeisen Bank Albania. It is not a live banking ' +
  'service. All legal texts, consents, fees and figures are drafts requiring final legal and ' +
  'compliance review and approval by Raiffeisen Bank Sh.a. before any real use.';

export type LegalDoc = { id: string; title: string; sections: { heading?: string; body: string }[] };

export const INFORMATION_NOTICE: LegalDoc = {
  id: 'information-notice',
  title: 'Processing of personal data',
  sections: [
    { heading: 'Who is responsible', body: 'Raiffeisen Bank Sh.a. (Albania), Tirana, is the data controller. You can reach the Data Protection Officer through the Bank’s official channels.' },
    { heading: 'What we process', body: 'Identity (name, date and place of birth, ID/document number, nationality), contact (phone, email, address), your ID image and a biometric facial scan for the liveness check, tax data (residency, tax ID, FATCA status), and financial profile data (occupation, source of funds, expected activity).' },
    { heading: 'Why, and on what basis', body: 'To enter into and run your account contract; to meet legal obligations (AML/CTF — Law No. 9917/2008; CRS — Law No. 4/2020, and FATCA; banking regulation); with your consent for the biometric check and any optional marketing; and the Bank’s legitimate interest in fraud prevention and security.' },
    { heading: 'Who receives it', body: 'The Bank’s authorised staff and processors, the Bank of Albania, the Financial Intelligence Agency (AIF), the General Directorate of Taxation (and, via CRS/FATCA, foreign tax authorities), the Albanian Deposit Insurance Agency (ASD), and others required by law.' },
    { heading: 'How long we keep it', body: 'For the life of the relationship and afterwards as required by AML and banking law — generally at least 5 years.' },
    { heading: 'Your rights (Law No. 124/2024)', body: 'Access, rectification, erasure, restriction, objection, portability, and withdrawal of consent at any time (without affecting earlier processing). Data we must keep by law cannot be deleted on request. Complaints: the Information and Data Protection Commissioner (idp.al). Automated checks are used only to verify you; no fully automated decision with legal effect is taken without safeguards.' },
  ],
};

export const DEPOSIT_INSURANCE: LegalDoc = {
  id: 'deposit-insurance',
  title: 'Your money is protected',
  sections: [
    { body: 'Deposits at Raiffeisen Bank Sh.a. are insured by the Albanian Deposit Insurance Agency (Agjencia e Sigurimit të Depozitave — ASD) under Law No. 53/2014 “On Deposit Insurance”, as amended.' },
    { heading: 'How much is covered', body: '100% of your eligible deposits up to a maximum of 2,500,000 ALL (about €26,000, indicative) per depositor, per bank — the total across all your eligible accounts here, in any currency.' },
    { heading: 'Foreign currency', body: 'Foreign-currency deposits are converted to ALL at the Bank of Albania official rate on the day the bank is placed into compulsory liquidation.' },
    { heading: 'What is excluded', body: 'Some deposits are excluded by law (amounts above the limit, anonymous accounts, funds linked to money laundering, and others). Full terms: asd.gov.al.' },
  ],
};

export const KYC_AML_NOTICE: LegalDoc = {
  id: 'aml-notice',
  title: 'Why we verify your identity',
  sections: [
    { body: 'By law, a bank must confirm who you are before opening an account (Know Your Customer). This is required under Law No. 9917/2008 “On the Prevention of Money Laundering and the Financing of Terrorism”, as amended.' },
    { heading: 'What this means', body: 'We read your official ID and run an automatic liveness check to confirm you are a real person and that you match your document. No human watches the video in real time.' },
    { heading: 'Honest declarations', body: 'You confirm you act on your own behalf (beneficial owner), declare whether you are a Politically Exposed Person, and confirm your funds are not linked to illegal activity. Knowingly false declarations are an offence.' },
  ],
};

// Consent rows — the exact, youth-appropriate strings.
export type Consent = { id: string; label: string; mandatory: boolean };

export const CONSENTS: Consent[] = [
  { id: 'personal_data_processing', mandatory: true, label: 'I have read and agree to the Information Notice on the Processing of Personal Data by Raiffeisen Bank Sh.a., under Law No. 124/2024 “On the Protection of Personal Data”.' },
  { id: 'framework_agreement', mandatory: true, label: 'I accept the Framework Agreement, the General Terms & Conditions, the Tariff/Fees schedule and the Privacy Policy for my account and card.' },
  { id: 'deposit_guarantee_ack', mandatory: true, label: 'I confirm I have received and read the depositor information about deposit insurance from the Albanian Deposit Insurance Agency (ASD) before opening my account.' },
  { id: 'kyc_aml_declarations', mandatory: true, label: 'I declare the information I gave is true and complete, that I act on my own behalf as beneficial owner, that I am not a Politically Exposed Person (or have declared if I am), and that my funds do not derive from money laundering or illegal activity.' },
  { id: 'crs_fatca_self_certification', mandatory: true, label: 'I certify my tax-residency / tax identification number (CRS) and FATCA status are accurate, and I will tell the Bank if they change.' },
  { id: 'biometric_processing', mandatory: true, label: 'I consent to the automated processing of my facial image (liveness check) for the sole purpose of verifying my identity during onboarding.' },
  { id: 'marketing_communications', mandatory: false, label: 'Send me personalised offers, news and rewards from Raiffeisen by email, SMS, push and in-app. (Optional — turn off anytime.)' },
  { id: 'profiling_personalisation', mandatory: false, label: 'Use my activity to personalise offers and quests for me. (Optional.)' },
];
