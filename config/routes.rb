RedmineApp::Application.routes.draw do
  get 'sla/dashboard', to: 'sla_dashboard#index', as: 'sla_dashboard'
  resources :sla_rules, only: [:index, :new, :create, :edit, :update, :destroy]
  get 'issues/:issue_id/sla_status', to: 'sla_issues#status', as: 'issue_sla_status'
end
