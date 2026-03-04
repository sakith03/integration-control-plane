/**
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import { Alert, Button, Checkbox, FormControlLabel, PageContent, Stack, TextField, Typography } from '@wso2/oxygen-ui';
import { ArrowLeft } from '@wso2/oxygen-ui-icons-react';
import { useState, type JSX } from 'react';
import { useNavigate } from 'react-router';
import { useCreateEnvironment } from '../api/mutations';
import { useAllEnvironments } from '../api/queries';
import { resourceUrl, type OrgScope } from '../nav';

function formatErrorMessage(error: Error): string {
  const message = error.message || '';
  const lowerMessage = message.toLowerCase();

  // Check for duplicate/conflict errors - expanded patterns
  if (lowerMessage.includes('already exists') || lowerMessage.includes('duplicate') || lowerMessage.includes('exists') || lowerMessage.includes('conflict') || lowerMessage.includes('unique')) {
    return 'An environment with this name already exists. Please choose a different name.';
  }

  // Handle generic backend error - likely a duplicate or constraint violation
  if (lowerMessage.includes('unexpected error') && lowerMessage.includes('administrator')) {
    return 'Unable to create environment. This name may already be in use or violates system constraints.';
  }

  // Check for validation errors
  if (lowerMessage.includes('invalid') || lowerMessage.includes('validation')) {
    return `Invalid input: ${message}`;
  }

  // Check for permission errors
  if (lowerMessage.includes('permission') || lowerMessage.includes('unauthorized') || lowerMessage.includes('forbidden')) {
    return 'You do not have permission to create environments.';
  }

  // If there's a meaningful error message, return it
  if (message && !lowerMessage.includes('unexpected') && !lowerMessage.includes('administrator') && !lowerMessage.includes('please contact') && message.length > 0) {
    // If the message seems generic, provide better context
    if (lowerMessage.includes('failed') || lowerMessage.includes('error')) {
      return `Unable to create environment: ${message}`;
    }
    return message;
  }

  return 'Failed to create environment. Please try again or contact support if the issue persists.';
}

export default function CreateEnvironment(scope: OrgScope): JSX.Element {
  const navigate = useNavigate();

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [critical, setCritical] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mutation = useCreateEnvironment();
  const { data: existingEnvironments } = useAllEnvironments();

  const submit = () => {
    setError(null);

    // Client-side duplicate check
    const normalizedName = name.trim().toLowerCase();
    const isDuplicate = existingEnvironments?.some((env) => env.name.toLowerCase() === normalizedName);

    if (isDuplicate) {
      setError('An environment with this name already exists. Please choose a different name.');
      return;
    }

    const trimmedName = name.trim();
    mutation.mutate(
      { name: trimmedName, description: description.trim(), critical },
      {
        onSuccess: () => navigate(resourceUrl(scope, 'environments'), { state: { success: true, environmentName: trimmedName } }),
        onError: (err) => {
          console.error('Environment creation error:', err.message); // Debug log
          setError(formatErrorMessage(err));
        },
      },
    );
  };

  return (
    <PageContent>
      <Button startIcon={<ArrowLeft size={16} />} onClick={() => navigate(resourceUrl(scope, 'environments'))} sx={{ mb: 2 }}>
        Back to Environments
      </Button>

      <Typography variant="h1" sx={{ mb: 4 }}>
        Create Environment
      </Typography>

      {error && (
        <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3, maxWidth: 600 }}>
          {error}
        </Alert>
      )}

      <Stack gap={3} sx={{ maxWidth: 600, mb: 4 }}>
        <TextField label="Name" placeholder="My-New-Environment" value={name} onChange={(e) => setName(e.target.value)} fullWidth />
        <TextField label="Description" value={description} onChange={(e) => setDescription(e.target.value)} fullWidth />
        <FormControlLabel control={<Checkbox checked={critical} onChange={(_, v) => setCritical(v)} />} label="Mark as Critical Environment" />
      </Stack>

      <Stack direction="row" gap={2}>
        <Button variant="outlined" onClick={() => navigate(resourceUrl(scope, 'environments'))}>
          Cancel
        </Button>
        <Button variant="contained" onClick={submit} disabled={!name.trim() || mutation.isPending}>
          Create
        </Button>
      </Stack>
    </PageContent>
  );
}
