<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IssueBuildTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_issues_a_deterministic_token_from_the_token_option(): void
    {
        $user = User::factory()->create([
            'email' => 'astro-build@geniuscorp.example',
        ]);

        $this->artisan('geo:issue-build-token', [
            '--token' => 'build-token-for-test',
        ])->assertSuccessful();

        $token = $user->tokens()->where('name', 'astro-build')->firstOrFail();

        $this->assertSame(hash('sha256', 'build-token-for-test'), $token->token);
        $this->assertSame(['content:read'], $token->abilities);
    }
}
