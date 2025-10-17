import { useTranslation } from 'react-i18next';

export function PrivacyPolicyPage() {
  const { t } = useTranslation();

  return (
    <div className='min-h-screen bg-gray-50 py-12'>
      <div className='max-w-4xl mx-auto px-4 sm:px-6 lg:px-8'>
        <div className='bg-white shadow-lg rounded-lg overflow-hidden'>
          <div className='px-6 py-8 sm:px-8'>
            <header className='mb-8'>
              <h1 className='text-3xl font-bold text-gray-900 mb-4'>
                {t('legal.privacyPolicy.title')}
              </h1>
              <p className='text-gray-600'>
                {t('legal.privacyPolicy.lastUpdated')}: {new Date().toLocaleDateString()}
              </p>
            </header>

            <div className='prose prose-lg max-w-none'>
              {/* 1. Información que Recopilamos */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.informationWeCollect.title')}
                </h2>
                <div className='space-y-4'>
                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.informationWeCollect.personalInfo.title')}
                    </h3>
                    <ul className='list-disc list-inside space-y-2 text-gray-700'>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.personalInfo.email')}
                      </li>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.personalInfo.name')}
                      </li>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.personalInfo.phone')}
                      </li>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.personalInfo.dateOfBirth'
                        )}
                      </li>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.personalInfo.medicalInfo'
                        )}
                      </li>
                    </ul>
                  </div>

                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.title')}
                    </h3>
                    <p className='text-gray-700 mb-2'>
                      {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.description')}
                    </p>
                    <ul className='list-disc list-inside space-y-2 text-gray-700'>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.google')}
                      </li>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.facebook')}
                      </li>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.apple')}
                      </li>
                      <li>
                        {t('legal.privacyPolicy.sections.informationWeCollect.oauthInfo.microsoft')}
                      </li>
                    </ul>
                  </div>

                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.informationWeCollect.technicalInfo.title')}
                    </h3>
                    <ul className='list-disc list-inside space-y-2 text-gray-700'>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.technicalInfo.ipAddress'
                        )}
                      </li>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.technicalInfo.browserInfo'
                        )}
                      </li>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.technicalInfo.deviceInfo'
                        )}
                      </li>
                      <li>
                        {t(
                          'legal.privacyPolicy.sections.informationWeCollect.technicalInfo.usageData'
                        )}
                      </li>
                    </ul>
                  </div>
                </div>
              </section>

              {/* 2. Cómo Usamos la Información */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.howWeUseInfo.title')}
                </h2>
                <ul className='list-disc list-inside space-y-2 text-gray-700'>
                  <li>{t('legal.privacyPolicy.sections.howWeUseInfo.provideServices')}</li>
                  <li>{t('legal.privacyPolicy.sections.howWeUseInfo.scheduleAppointments')}</li>
                  <li>{t('legal.privacyPolicy.sections.howWeUseInfo.communicate')}</li>
                  <li>{t('legal.privacyPolicy.sections.howWeUseInfo.improveServices')}</li>
                  <li>{t('legal.privacyPolicy.sections.howWeUseInfo.compliance')}</li>
                </ul>
              </section>

              {/* 3. Compartir Información */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.sharingInfo.title')}
                </h2>
                <div className='space-y-4'>
                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.sharingInfo.healthcareProviders.title')}
                    </h3>
                    <p className='text-gray-700'>
                      {t(
                        'legal.privacyPolicy.sections.sharingInfo.healthcareProviders.description'
                      )}
                    </p>
                  </div>

                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.sharingInfo.serviceProviders.title')}
                    </h3>
                    <p className='text-gray-700'>
                      {t('legal.privacyPolicy.sections.sharingInfo.serviceProviders.description')}
                    </p>
                  </div>

                  <div>
                    <h3 className='text-xl font-medium text-gray-800 mb-2'>
                      {t('legal.privacyPolicy.sections.sharingInfo.legalRequirements.title')}
                    </h3>
                    <p className='text-gray-700'>
                      {t('legal.privacyPolicy.sections.sharingInfo.legalRequirements.description')}
                    </p>
                  </div>
                </div>
              </section>

              {/* 4. Seguridad de Datos */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.dataSecurity.title')}
                </h2>
                <div className='space-y-4'>
                  <p className='text-gray-700'>
                    {t('legal.privacyPolicy.sections.dataSecurity.description')}
                  </p>
                  <ul className='list-disc list-inside space-y-2 text-gray-700'>
                    <li>{t('legal.privacyPolicy.sections.dataSecurity.encryption')}</li>
                    <li>{t('legal.privacyPolicy.sections.dataSecurity.accessControls')}</li>
                    <li>{t('legal.privacyPolicy.sections.dataSecurity.auditLogs')}</li>
                    <li>{t('legal.privacyPolicy.sections.dataSecurity.hipaaCompliance')}</li>
                    <li>{t('legal.privacyPolicy.sections.dataSecurity.regularAudits')}</li>
                  </ul>
                </div>
              </section>

              {/* 5. Sus Derechos */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.yourRights.title')}
                </h2>
                <ul className='list-disc list-inside space-y-2 text-gray-700'>
                  <li>{t('legal.privacyPolicy.sections.yourRights.access')}</li>
                  <li>{t('legal.privacyPolicy.sections.yourRights.correction')}</li>
                  <li>{t('legal.privacyPolicy.sections.yourRights.deletion')}</li>
                  <li>{t('legal.privacyPolicy.sections.yourRights.portability')}</li>
                  <li>{t('legal.privacyPolicy.sections.yourRights.restriction')}</li>
                  <li>{t('legal.privacyPolicy.sections.yourRights.objection')}</li>
                </ul>
              </section>

              {/* 6. Cookies y Tecnologías Similares */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.cookies.title')}
                </h2>
                <p className='text-gray-700 mb-4'>
                  {t('legal.privacyPolicy.sections.cookies.description')}
                </p>
                <ul className='list-disc list-inside space-y-2 text-gray-700'>
                  <li>{t('legal.privacyPolicy.sections.cookies.essential')}</li>
                  <li>{t('legal.privacyPolicy.sections.cookies.analytics')}</li>
                  <li>{t('legal.privacyPolicy.sections.cookies.preferences')}</li>
                </ul>
              </section>

              {/* 7. Retención de Datos */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.dataRetention.title')}
                </h2>
                <p className='text-gray-700'>
                  {t('legal.privacyPolicy.sections.dataRetention.description')}
                </p>
              </section>

              {/* 8. Cambios a esta Política */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.changes.title')}
                </h2>
                <p className='text-gray-700'>
                  {t('legal.privacyPolicy.sections.changes.description')}
                </p>
              </section>

              {/* 9. Contacto */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.contact.title')}
                </h2>
                <div className='bg-gray-50 p-6 rounded-lg'>
                  <p className='text-gray-700 mb-4'>
                    {t('legal.privacyPolicy.sections.contact.description')}
                  </p>
                  <div className='space-y-2'>
                    <p className='text-gray-700'>
                      <strong>{t('legal.privacyPolicy.sections.contact.email')}:</strong>{' '}
                      privacy@adyela.care
                    </p>
                    <p className='text-gray-700'>
                      <strong>{t('legal.privacyPolicy.sections.contact.address')}:</strong>{' '}
                      {t('legal.privacyPolicy.sections.contact.addressValue')}
                    </p>
                    <p className='text-gray-700'>
                      <strong>{t('legal.privacyPolicy.sections.contact.phone')}:</strong> +1 (555)
                      123-4567
                    </p>
                  </div>
                </div>
              </section>

              {/* 10. Cumplimiento HIPAA */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  {t('legal.privacyPolicy.sections.hipaa.title')}
                </h2>
                <div className='bg-blue-50 p-6 rounded-lg border-l-4 border-blue-400'>
                  <p className='text-gray-700 mb-4'>
                    {t('legal.privacyPolicy.sections.hipaa.description')}
                  </p>
                  <ul className='list-disc list-inside space-y-2 text-gray-700'>
                    <li>{t('legal.privacyPolicy.sections.hipaa.administrative')}</li>
                    <li>{t('legal.privacyPolicy.sections.hipaa.physical')}</li>
                    <li>{t('legal.privacyPolicy.sections.hipaa.technical')}</li>
                    <li>{t('legal.privacyPolicy.sections.hipaa.breachNotification')}</li>
                  </ul>
                </div>
              </section>

              {/* 11. Eliminación de Datos */}
              <section className='mb-8'>
                <h2 className='text-2xl font-semibold text-gray-900 mb-4'>
                  Derechos de Eliminación de Datos
                </h2>
                <div className='bg-red-50 p-6 rounded-lg border-l-4 border-red-400'>
                  <p className='text-gray-700 mb-4'>
                    Tienes el derecho de solicitar la eliminación de tus datos personales en
                    cualquier momento. Procesaremos tu solicitud dentro de 30 días y eliminaremos
                    permanentemente tus datos de nuestros sistemas.
                  </p>
                  <div className='bg-white p-4 rounded-lg border border-red-200'>
                    <p className='text-red-800 font-medium mb-2'>Solicitar Eliminación de Datos</p>
                    <p className='text-red-700 text-sm mb-3'>
                      Para solicitar la eliminación de tus datos personales, visita nuestra página
                      de eliminación de datos.
                    </p>
                    <a
                      href='/data-deletion'
                      className='inline-flex items-center px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 transition-colors duration-200'
                    >
                      Solicitar Eliminación de Datos
                    </a>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
