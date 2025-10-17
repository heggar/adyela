import { useState } from 'react';
import { useTranslation } from 'react-i18next';

interface DataDeletionRequest {
  email: string;
  reason?: string;
}

interface DataDeletionResponse {
  request_id: string;
  status: string;
  message: string;
  estimated_completion?: string;
}

export function DataDeletionPage() {
  const { t } = useTranslation();
  const [formData, setFormData] = useState<DataDeletionRequest>({
    email: '',
    reason: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [response, setResponse] = useState<DataDeletionResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000';
      const res = await fetch(`${apiBaseUrl}/api/v1/data-deletion/request`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }

      const data = await res.json();
      setResponse(data);
      setSubmitted(true);
    } catch (err) {
      console.error('Error submitting data deletion request:', err);
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  if (submitted && response) {
    return (
      <div className='min-h-screen bg-secondary-50 py-12 px-4 sm:px-6 lg:px-8'>
        <div className='max-w-2xl mx-auto bg-white shadow-lg rounded-lg p-8'>
          <div className='text-center'>
            <div className='mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4'>
              <svg
                className='h-6 w-6 text-green-600'
                fill='none'
                viewBox='0 0 24 24'
                stroke='currentColor'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M5 13l4 4L19 7'
                />
              </svg>
            </div>
            <h1 className='text-3xl font-bold text-secondary-900 mb-4'>
              {t('dataDeletion.requestSubmitted')}
            </h1>
            <p className='text-lg text-secondary-600 mb-6'>
              {t('dataDeletion.requestSubmittedDescription')}
            </p>
          </div>

          <div className='bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6'>
            <h3 className='text-lg font-semibold text-blue-900 mb-2'>
              {t('dataDeletion.requestDetails')}
            </h3>
            <div className='space-y-2 text-sm'>
              <p>
                <strong>{t('dataDeletion.requestId')}:</strong> {response.request_id}
              </p>
              <p>
                <strong>{t('dataDeletion.status')}:</strong>
                <span className='ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs'>
                  {response.status}
                </span>
              </p>
              {response.estimated_completion && (
                <p>
                  <strong>{t('dataDeletion.estimatedCompletion')}:</strong>
                  {new Date(response.estimated_completion).toLocaleDateString()}
                </p>
              )}
            </div>
          </div>

          <div className='bg-gray-50 border border-gray-200 rounded-lg p-6'>
            <h3 className='text-lg font-semibold text-gray-900 mb-2'>
              {t('dataDeletion.nextSteps')}
            </h3>
            <ul className='space-y-2 text-sm text-gray-700'>
              <li className='flex items-start'>
                <span className='flex-shrink-0 w-5 h-5 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-xs font-semibold mr-3 mt-0.5'>
                  1
                </span>
                {t('dataDeletion.nextStep1')}
              </li>
              <li className='flex items-start'>
                <span className='flex-shrink-0 w-5 h-5 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-xs font-semibold mr-3 mt-0.5'>
                  2
                </span>
                {t('dataDeletion.nextStep2')}
              </li>
              <li className='flex items-start'>
                <span className='flex-shrink-0 w-5 h-5 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-xs font-semibold mr-3 mt-0.5'>
                  3
                </span>
                {t('dataDeletion.nextStep3')}
              </li>
            </ul>
          </div>

          <div className='mt-6 text-center'>
            <a href='/privacy' className='text-primary-600 hover:text-primary-700 underline'>
              {t('dataDeletion.viewPrivacyPolicy')}
            </a>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className='min-h-screen bg-secondary-50 py-12 px-4 sm:px-6 lg:px-8'>
      <div className='max-w-4xl mx-auto'>
        <div className='bg-white shadow-lg rounded-lg p-8'>
          <div className='text-center mb-8'>
            <h1 className='text-4xl font-extrabold text-secondary-900 mb-4'>
              {t('dataDeletion.title')}
            </h1>
            <p className='text-lg text-secondary-600'>{t('dataDeletion.description')}</p>
          </div>

          <div className='grid md:grid-cols-2 gap-8 mb-8'>
            <div>
              <h2 className='text-2xl font-bold text-secondary-800 mb-4'>
                {t('dataDeletion.whatWeDelete')}
              </h2>
              <ul className='space-y-2 text-secondary-700'>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.personalInfo')}
                </li>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.medicalRecords')}
                </li>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.appointmentHistory')}
                </li>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.authenticationData')}
                </li>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.usageAnalytics')}
                </li>
                <li className='flex items-start'>
                  <svg
                    className='flex-shrink-0 w-5 h-5 text-red-500 mt-0.5 mr-2'
                    fill='currentColor'
                    viewBox='0 0 20 20'
                  >
                    <path
                      fillRule='evenodd'
                      d='M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'
                      clipRule='evenodd'
                    />
                  </svg>
                  {t('dataDeletion.uploadedFiles')}
                </li>
              </ul>
            </div>

            <div>
              <h2 className='text-2xl font-bold text-secondary-800 mb-4'>
                {t('dataDeletion.importantNotes')}
              </h2>
              <div className='space-y-4'>
                <div className='bg-yellow-50 border border-yellow-200 rounded-lg p-4'>
                  <h3 className='font-semibold text-yellow-800 mb-2'>
                    {t('dataDeletion.irreversible')}
                  </h3>
                  <p className='text-sm text-yellow-700'>
                    {t('dataDeletion.irreversibleDescription')}
                  </p>
                </div>

                <div className='bg-blue-50 border border-blue-200 rounded-lg p-4'>
                  <h3 className='font-semibold text-blue-800 mb-2'>
                    {t('dataDeletion.processingTime')}
                  </h3>
                  <p className='text-sm text-blue-700'>
                    {t('dataDeletion.processingTimeDescription')}
                  </p>
                </div>

                <div className='bg-gray-50 border border-gray-200 rounded-lg p-4'>
                  <h3 className='font-semibold text-gray-800 mb-2'>
                    {t('dataDeletion.legalRetention')}
                  </h3>
                  <p className='text-sm text-gray-700'>
                    {t('dataDeletion.legalRetentionDescription')}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className='border-t pt-8'>
            <h2 className='text-2xl font-bold text-secondary-800 mb-6 text-center'>
              {t('dataDeletion.requestForm')}
            </h2>

            <form onSubmit={handleSubmit} className='max-w-2xl mx-auto'>
              <div className='space-y-6'>
                <div>
                  <label
                    htmlFor='email'
                    className='block text-sm font-medium text-secondary-700 mb-2'
                  >
                    {t('dataDeletion.emailAddress')} *
                  </label>
                  <input
                    type='email'
                    id='email'
                    name='email'
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                    className='w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500'
                    placeholder={t('dataDeletion.emailPlaceholder')}
                  />
                  <p className='mt-1 text-sm text-gray-500'>{t('dataDeletion.emailDescription')}</p>
                </div>

                <div>
                  <label
                    htmlFor='reason'
                    className='block text-sm font-medium text-secondary-700 mb-2'
                  >
                    {t('dataDeletion.reason')}
                  </label>
                  <textarea
                    id='reason'
                    name='reason'
                    value={formData.reason}
                    onChange={handleInputChange}
                    rows={4}
                    className='w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500'
                    placeholder={t('dataDeletion.reasonPlaceholder')}
                  />
                  <p className='mt-1 text-sm text-gray-500'>
                    {t('dataDeletion.reasonDescription')}
                  </p>
                </div>

                {error && (
                  <div className='bg-red-50 border border-red-200 rounded-lg p-4'>
                    <p className='text-sm text-red-600'>
                      {t('dataDeletion.error')}: {error}
                    </p>
                  </div>
                )}

                <div className='bg-gray-50 border border-gray-200 rounded-lg p-4'>
                  <div className='flex items-start'>
                    <input
                      type='checkbox'
                      id='confirm'
                      required
                      className='mt-1 h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded'
                    />
                    <label htmlFor='confirm' className='ml-3 text-sm text-gray-700'>
                      {t('dataDeletion.confirmation')}
                    </label>
                  </div>
                </div>

                <div className='text-center'>
                  <button
                    type='submit'
                    disabled={isSubmitting}
                    className='bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white font-medium py-3 px-8 rounded-lg transition-colors duration-200'
                  >
                    {isSubmitting ? t('dataDeletion.submitting') : t('dataDeletion.submitRequest')}
                  </button>
                </div>
              </div>
            </form>
          </div>

          <div className='mt-8 text-center text-sm text-gray-500'>
            <p>
              {t('dataDeletion.questions')}{' '}
              <a
                href='mailto:privacy@adyela.care'
                className='text-primary-600 hover:text-primary-700 underline'
              >
                privacy@adyela.care
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
